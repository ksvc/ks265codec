package com.ksyun.media.ksy265codec.demo.ui;

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentActivity;
import android.support.v4.app.FragmentTabHost;
import android.support.v4.view.ViewPager;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TabHost;
import android.widget.TabWidget;
import android.widget.TextView;

import com.ksyun.media.ksy265codec.demo.R;

import java.util.ArrayList;
import java.util.List;

public class MainActivity extends FragmentActivity implements
        ViewPager.OnPageChangeListener, TabHost.OnTabChangeListener {

    private FragmentTabHost mTabHost;
    private LayoutInflater mLayoutInflater;
    private Class fragmentArray[] = { EncoderFragment.class, DecoderFragment.class };
    private int tab_imageViewArray[] = { R.drawable.tab_home_btn, R.drawable.tab_home_btn };
    private String tab_textViewArray[] = { "编码", "解码"};
    private List<Fragment> list = new ArrayList<Fragment>();
    private ViewPager mViewPager;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        initView();//初始化控件
        initPage();//初始化页面
    }

    //    控件初始化控件
    private void initView() {
        mViewPager = (ViewPager) findViewById(R.id.pager);

        /*实现OnPageChangeListener接口,目的是监听Tab选项卡的变化，然后通知ViewPager适配器切换界面*/
        /*简单来说,是为了让ViewPager滑动的时候能够带着底部菜单联动*/

        mViewPager.addOnPageChangeListener(this);//设置页面切换时的监听器
        mLayoutInflater = LayoutInflater.from(this);//加载布局管理器

        /*实例化FragmentTabHost对象并进行绑定*/
        mTabHost = (FragmentTabHost) findViewById(android.R.id.tabhost);//绑定tahost
        mTabHost.setup(this, getSupportFragmentManager(), R.id.pager);//绑定viewpager

        /*实现setOnTabChangedListener接口,目的是为监听界面切换），然后实现TabHost里面图片文字的选中状态切换*/
        /*简单来说,是为了当点击下面菜单时,上面的ViewPager能滑动到对应的Fragment*/
        mTabHost.setOnTabChangedListener(this);

        int count = tab_textViewArray.length;

        /*新建Tabspec选项卡并设置Tab菜单栏的内容和绑定对应的Fragment*/
        for (int i = 0; i < count; i++) {
            // 给每个Tab按钮设置标签、图标和文字
            TabHost.TabSpec tabSpec = mTabHost.newTabSpec(tab_textViewArray[i])
                    .setIndicator(getTabItemView(i));
            // 将Tab按钮添加进Tab选项卡中，并绑定Fragment
            mTabHost.addTab(tabSpec, fragmentArray[i], null);
            mTabHost.setTag(i);
            mTabHost.getTabWidget().getChildAt(i)
                    .setBackgroundResource(R.drawable.selector_tab_background);//设置Tab被选中的时候颜色改变
        }
    }

    /*初始化Fragment*/
    private void initPage() {
        EncoderFragment fragment1 = new EncoderFragment();
        DecoderFragment fragment2 = new DecoderFragment();

        list.add(fragment1);
        list.add(fragment2);

        //绑定Fragment适配器
        mViewPager.setAdapter(new MyFragmentAdapter(getSupportFragmentManager(), list));
        mTabHost.getTabWidget().setDividerDrawable(null);
    }

    private View getTabItemView(int i) {
        //将xml布局转换为view对象
        View view = mLayoutInflater.inflate(R.layout.tab_content, null);
        //利用view对象，找到布局中的组件,并设置内容，然后返回视图
        ImageView mTab_ImageView = (ImageView) view
                .findViewById(R.id.tab_imageview);
        TextView mTab_TextView = (TextView) view.findViewById(R.id.tab_textview);

        mTab_ImageView.setBackgroundResource(tab_imageViewArray[i]);
        mTab_TextView.setText(tab_textViewArray[i]);
        return view;
    }


    @Override
    public void onPageScrollStateChanged(int arg0) {

    }//arg0 ==1的时候表示正在滑动，arg0==2的时候表示滑动完毕了，arg0==0的时候表示什么都没做，就是停在那。

    @Override
    public void onPageScrolled(int arg0, float arg1, int arg2) {

    }//表示在前一个页面滑动到后一个页面的时候，在前一个页面滑动前调用的方法

    @Override
    public void onPageSelected(int arg0) {//arg0是表示你当前选中的页面位置Postion，这事件是在你页面跳转完毕的时候调用的。
        TabWidget widget = mTabHost.getTabWidget();
        int oldFocusability = widget.getDescendantFocusability();
        widget.setDescendantFocusability(ViewGroup.FOCUS_BLOCK_DESCENDANTS);//设置View覆盖子类控件而直接获得焦点
        mTabHost.setCurrentTab(arg0);//根据位置Postion设置当前的Tab
        widget.setDescendantFocusability(oldFocusability);//设置取消分割线
    }

    @Override
    public void onTabChanged(String tabId) {//Tab改变的时候调用
        int position = mTabHost.getCurrentTab();
        mViewPager.setCurrentItem(position);//把选中的Tab的位置赋给适配器，让它控制页面切换
    }
}
