package com.webdesk.app.activity;

import android.Manifest;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.util.Log;
import android.view.View;
import android.view.WindowManager;
import android.widget.ProgressBar;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.databinding.DataBindingUtil;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.webdesk.app.R;
import com.webdesk.app.adapter.MovieAdapter;
import com.webdesk.app.api.Response.MovieResponse;
import com.webdesk.app.common.Utils;
import com.webdesk.app.databinding.ActivityMovielistBinding;
import com.webdesk.app.di.ActivityBase;
import com.webdesk.app.viewmodel.MovieViewModel;

import java.io.BufferedInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URL;
import java.net.URLConnection;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

import javax.inject.Inject;

import pub.devrel.easypermissions.AfterPermissionGranted;
import pub.devrel.easypermissions.AppSettingsDialog;
import pub.devrel.easypermissions.EasyPermissions;

/**
 * Created by John A,25 Sept 2020
 */
public class MovieListActivity extends ActivityBase<MovieViewModel>
        implements EasyPermissions.PermissionCallbacks, MovieAdapter.onItemClickListener {

    private static final int STORAGE_PER = 222;
    @Inject
    MovieViewModel userViewModel;
    private ActivityMovieListBinding mBinding;
    private ArrayList<MovieResponse.ResultsBean> allDataList;
    private MovieAdapter userAdapter;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        mBinding = DataBindingUtil.setContentView(this, R.layout.activity_Movielist);
        mBinding.setUserlist(userViewModel);
        setupToolbar();
        checkPermission();
        getMovieList();
        setListener();
    }

    private void getMovieList() {
        if (myApplication.isInternetConnected()) {
            getWindow().setFlags(WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
                    WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE);
            userViewModel.getMovieiteApi(myApplication);
        } else {
            Utils.showToast(mActivity, getResources().getString(R.string.message_no_connection_check));
        }
    }

/*
*  Setup listener for the viewmodels
*/
    private void setListener() {
        userViewModel.getLivememberdata().observe(this, memberResponse -> {
            // update UI
            hideKeyboard();
            getWindow().clearFlags(WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE);
            if (memberResponse != null) {
                allDataList = new ArrayList<>();
                allDataList.addAll(memberResponse.getResults());

                if (!allDataList.isEmpty()) {
                    mBinding.rlMovielist.setVisibility(View.VISIBLE);
                    mBinding.tvnodata.setVisibility(View.GONE);
                    userAdapter = new MovieAdapter(this, mActivity, allDataList);
                    LinearLayoutManager linearLayoutManager = new LinearLayoutManager(this);
                    mBinding.rlMovielist.setLayoutManager(linearLayoutManager);
                    mBinding.rlMovielist.setAdapter(userAdapter);
                } else {
                    mBinding.rlMovielist.setVisibility(View.GONE);
                    mBinding.tvnodata.setVisibility(View.VISIBLE);
                }
            }
        });

    }

    /**
     * setup toolbar
     */
    public void setupToolbar() {
        setSupportActionBar(mBinding.rlMain.toolbar);
        Objects.requireNonNull(getSupportActionBar()).setDisplayShowTitleEnabled(false);
        mBinding.rlMain.tvtitle.setText(R.string.home_title);
    }

    @Override
    protected void onResume() {
        super.onResume();
    }


    @Override
    public void onBackPressed() {
        super.onBackPressed();
        overridePendingTransition(R.anim.slide_in_left,
                R.anim.slide_out_right);
    }

    @AfterPermissionGranted(STORAGE_PER)
    private void checkPermission() {
        String[] perms = {Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.WRITE_EXTERNAL_STORAGE};
        if (EasyPermissions.hasPermissions(this, perms)) {

        } else {
            EasyPermissions.requestPermissions(this, getResources().getString(R.string.grant_storage_permission),
                    STORAGE_PER, perms);
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        // Forward results to EasyPermissions
        EasyPermissions.onRequestPermissionsResult(requestCode, permissions, grantResults, this);
    }

    @Override
    public void onPermissionsGranted(int requestCode, @NonNull List<String> perms) {

    }

    @Override
    public void onPermissionsDenied(int requestCode, @NonNull List<String> perms) {
        if (EasyPermissions.somePermissionPermanentlyDenied(this, perms)) {
            new AppSettingsDialog.Builder(this).build().show();
        }
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == STORAGE_PER && resultCode == RESULT_OK) {
        }
    }
}
