package com.ksyun.media.ksy265codec.demo.decoder.hevdecoder;

import android.graphics.Bitmap;
import android.graphics.Bitmap.Config;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.opengl.GLSurfaceView;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.Surface;
import android.view.Surface.OutOfResourcesException;
import android.view.SurfaceHolder;
import android.widget.TextView;

import java.io.File;
import java.io.FileFilter;
import java.util.regex.Pattern;

import com.ksyun.media.ksy265codec.demo.ui.Settings;

public class NativeMediaPlayer {
	public static final int MEDIA_INFO_FRAMERATE_VIDEO = 900;
	public static final int MEDIA_INFO_END_OF_FILE = 909;

	private int mNativeContext; // accessed by native methods
	private Surface mSurface;
	private GLSurfaceView mGLSurfaceView;
	private TextView mInfoTextView;
	private Bitmap mFrameBitmap = null;
	private int mDisplayWidth = 0;
	private int mDisplayHeight = 0;
	private int mDisplayFPS = -1;
	private int mDisplayAvgFPS = -1;
	private int mDecodeFPS = -1;
	private int mBitrateVideo = -1;
	private int mBitrateAudio = -1;
	private boolean mShowInfo = true;
	private boolean mShowInfoGL = true;
	private String mInfo = "";

	private OnCompletionListener mListener = null;
	private final Handler mMainHandler;
	private boolean mNeedSetup = true;

	public interface OnCompletionListener {
		public void onCompletion(int frame_count);
	}

	public void setCompletionListener(OnCompletionListener listener) {
		this.mListener = listener;
	}

	public NativeMediaPlayer() {
		mMainHandler = new Handler(Looper.getMainLooper());
	}

	public void init() {
		native_init();
	}

	public void setDisplay(SurfaceHolder sh) {
		if (sh != null) {
			mSurface = sh.getSurface();
		} else
			mSurface = null;
	}

	public void setGLDisplay(GLSurfaceView glView, TextView tv) {
		mGLSurfaceView = glView;
		mInfoTextView = tv;
	}

	public void setDisplaySize(int w, int h) {
		mDisplayHeight = h;
		mDisplayWidth = w;

		mNeedSetup = true;
	}

	/**
	 * Gets the number of cores available in this device, across all processors.
	 * Requires: Ability to peruse the filesystem at "/sys/devices/system/cpu"
	 * 
	 * @return The number of cores, or 1 if failed to get result
	 */
	private int getNumCores() {
		// Private Class to display only CPU devices in the directory listing
		class CpuFilter implements FileFilter {
			@Override
			public boolean accept(File pathname) {
				// Check if filename is "cpu", followed by a single digit number
				if (Pattern.matches("cpu[0-9]+", pathname.getName())) {
					return true;
				}
				return false;
			}
		}

		try {
			// Get directory containing CPU info
			File dir = new File("/sys/devices/system/cpu/");
			// Filter to only list the devices we care about
			File[] files = dir.listFiles(new CpuFilter());
			// Return the number of cores (virtual CPU devices)
			return files.length;
		} catch (Exception e) {
			// Default to return 1 core
			return 1;
		}
	}

	public int prepare(int type, int disableRender) {
		// android maintains the preferences for us, so use directly
		int num = Settings.getInstance().getDecoderSettings().getThreads();
		if (0 == num) {
			int cores = getNumCores();// Runtime.getRuntime().availableProcessors();
			if (cores <= 1)
				num = 1;
			else
				num = (cores < 5) ? ((cores * 3 + 1) / 2) : 8;
			Log.d("NativeMediaPlayer", cores + " cores detected! use " + num
					+ " threads.\n");
		}

		float fps = Settings.getInstance().getDecoderSettings().getFPS();

		return native_prepare(type, disableRender, num, fps);
	}

	public int prepare(int type, int disableRender,
					   int threadNum, float fps) {
		return native_prepare(type, disableRender, threadNum, fps);
	}

	public int start() {
		int w = getVideoWidth(), h = getVideoHeight();
		if (w > 0 && h > 0)
			mFrameBitmap = Bitmap.createBitmap(w, h, Config.RGB_565);
		return native_start();
	}

	public void stop() {
		native_stop();
		if (mFrameBitmap != null) {
			mFrameBitmap.recycle();
			mFrameBitmap = null;
		}
	}

	public void pause() {
		native_pause();
	}

	public void go() {
		native_go();
	}

	public void seekTo(int msec) {

	}

	public void setShowInfo(boolean show) {
		mShowInfo = show;
		if (mShowInfo == false && mInfoTextView != null) {
			mInfoTextView.setText("");
		}
	}

	private void setupDisplay() {
		int videoWidth = getVideoWidth(), videoHeight = getVideoHeight();
		int screenWidth, screenHeight, displayWidth = 0, displayHeight = 0;
		screenHeight = mDisplayHeight;
		screenWidth = mDisplayWidth;

		displayWidth = videoWidth;
		displayHeight = videoHeight;
		if (displayHeight > screenHeight) {
			displayHeight = screenHeight;
			displayWidth = displayHeight * videoWidth / videoHeight;
			displayWidth -= displayWidth % 4;
		}
		if (displayWidth > screenWidth) {
			displayWidth = screenWidth;
			displayHeight = displayWidth * videoHeight / videoWidth;
			displayHeight -= displayHeight % 4;
		}
		setDisplaySize(displayWidth, displayHeight);
	}

	/**
	 * Called from native code
	 */
	public int drawFrame(int width, int height) {
		boolean useGL = false;

		if (useGL) {

			mGLSurfaceView.requestRender();

			if (mShowInfoGL) {
				mInfo = "";
				Paint paint = new Paint();
				paint.setColor(Color.WHITE);
				paint.setTextSize(40);
				if (width > 0) {
					mInfo += ("Video Size:" + width + "x" + height);
				}
				if (mDisplayFPS > 0) {
					mInfo += ("    Display FPS:" + mDisplayFPS);
				}
				if (mDisplayAvgFPS > 0) {
					mInfo += String.format("    Average FPS:%.2f",
							mDisplayAvgFPS / 4096.0);
				}

				mInfoTextView.post(new Runnable() {
					@Override
					public void run() {
						mInfoTextView.setText(mInfo);
					}
				});

				mShowInfoGL = false;
			}

			return 0;
		}

		if (mSurface == null) {
			return 0;
		}

		if (mNeedSetup) {
			setupDisplay();
			mNeedSetup = false;
		}

		// draw without OpenGL
		Canvas canvas = null;
		try {
			canvas = mSurface.lockCanvas(null);
		} catch (IllegalArgumentException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (OutOfResourcesException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

		canvas.drawColor(Color.BLACK);

		if (null == mFrameBitmap || mFrameBitmap.getWidth() != width) {
			// video size has changed, we need to create a new frame bitmap
			// correspondingly
			mFrameBitmap = Bitmap.createBitmap(width, height, Config.RGB_565);
		}

		renderBitmap(mFrameBitmap);

		if (mDisplayWidth != mFrameBitmap.getWidth()) {
			Matrix matrix = new Matrix();
			float scaleWidth = ((float) mDisplayWidth) / width;
			float scaleHeight = ((float) mDisplayHeight) / height;
			matrix.postScale(scaleWidth, scaleHeight);
			matrix.postTranslate((canvas.getWidth() - mDisplayWidth) / 2,
					(canvas.getHeight() - mDisplayHeight) / 2);
			if (mFrameBitmap.getWidth() < 640) {
				// small bitmap, able to use filter
				Paint paint = new Paint();
				paint.setFilterBitmap(true);
				canvas.drawBitmap(mFrameBitmap, matrix, paint);
			} else {
				canvas.drawBitmap(mFrameBitmap, matrix, null);
			}
		} else {
			canvas.drawBitmap(mFrameBitmap,
					(canvas.getWidth() - mDisplayWidth) / 2,
					(canvas.getHeight() - mDisplayHeight) / 2, null);
		}

		if (mShowInfo) {
			Paint paint = new Paint();
			paint.setColor(Color.WHITE);
			paint.setTextSize(40);
			String info = "";
			if (width > 0) {
				info += ("Video Size:" + width + "x" + height);
			}
			if (mDisplayFPS > 0) {
				info += ("    Display FPS:" + mDisplayFPS);
			}
			if (mDisplayAvgFPS > 0) {
				info += String.format("    Average FPS:%.2f",
						mDisplayAvgFPS / 4096.0);
			}
			if (mDecodeFPS > 0) {
				info += ("    Decode FPS:" + mDecodeFPS);
			}
			canvas.drawText(info, 20, 60, paint);
			info = "";
			if (mBitrateVideo > 0) {
				info += "Bitrate: video " + Integer.toString(mBitrateVideo);
			}
			if (mBitrateAudio > 0) {
				info += ", audio " + Integer.toString(mBitrateAudio);
			}
			if (mBitrateVideo > 0 || mBitrateAudio > 0) {
				info += ", total "
						+ Integer.toString(mBitrateVideo + mBitrateAudio)
						+ " kbit/s";
			}
			canvas.drawText(info, 20, 100, paint);
		}

		mSurface.unlockCanvasAndPost(canvas);

		return 0;
	}

	/**
	 * Called from native code when an interesting event happens.
	 */
	public void postEventFromNative(int what, int arg1, int arg2) {
		switch (what) {
		case MEDIA_INFO_FRAMERATE_VIDEO:
			mDisplayFPS = arg1;
			mDisplayAvgFPS = arg2;
			if (mShowInfo) {
				mShowInfoGL = true;
			}
			break;
		case MEDIA_INFO_END_OF_FILE:
			final int frame_num = arg1;
			mMainHandler.post(new Runnable() {
				@Override
				public void run() {
					if (mListener != null) {
						mListener.onCompletion(frame_num);
					}
				}
			});

			break;
		}
	}

	// set output file name
	public void setOutput(String outputFileName) {
		native_set_output(outputFileName);
	}

	private native void native_init();

	private native int native_prepare(int decoderType, int disableRender, int threadNum, float renderFPS);

	private native int native_start();

	private native int native_stop();

	private native int native_pause();

	private native int native_go();

	private native int native_seekTo(int msec);

	private native static int hasNeon();

	public native int setDataSource(String path);

	public native int getVideoWidth();

	public native int getVideoHeight();

	public native boolean isPlaying();

	public native int getCurrentPosition();

	public native float getDuration();

	public native float getDecodeTime();

	public native float getDecodeFPS();

	private native static void renderBitmap(Bitmap bitmap);

	public native void native_set_output(String output);

	public native String getVersion();

	static {
		System.loadLibrary("lenthevcdec");
		System.loadLibrary("jniplayer");
	}

}
