
/*
Copyright 2010 Google Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package com.yell.labs.mexicanwave;

import java.io.IOException;

import android.app.Activity;
import android.content.Context;
import android.hardware.Camera;
import android.hardware.Camera.Parameters;
import android.util.AttributeSet;
import android.view.SurfaceHolder;
import android.view.SurfaceView;

class PreviewSurface extends SurfaceView implements SurfaceHolder.Callback {
	
    SurfaceHolder mHolder;
    Context mContext;
    Camera mCamera;
    Camera.Parameters mParameters;
    Callback mCallback;
    Activity mActivity;
    boolean hasCamera = false;
    boolean hasSurface = false;
    boolean isViewfinder = false;
    
    PreviewSurface(Context context) {
        super(context);
        mContext = context;
        initHolder();
    }

    public PreviewSurface(Context context, AttributeSet attrs, int defStyle) {
		super(context, attrs, defStyle);
		initHolder();
	}

	public PreviewSurface(Context context, AttributeSet attrs) {
		super(context, attrs);
		initHolder();
	}
	
	private void initHolder() {
        mHolder = getHolder();
        mHolder.addCallback(this);
        mHolder.setType(SurfaceHolder.SURFACE_TYPE_PUSH_BUFFERS);
	}

	public void surfaceCreated(SurfaceHolder holder) {
		mHolder = holder;
		initCamera();
    }

    public void surfaceDestroyed(SurfaceHolder holder) {
    	releaseCamera();
    }

    public void surfaceChanged(SurfaceHolder holder, int format, int w, int h) {
    	if (hasCamera) {
	    	mParameters = mCamera.getParameters();
	        mCamera.startPreview();
	        mCallback.cameraReady();
			hasSurface = true;
    	}
    }
    
    
    public void initCamera() {
    	if (!hasCamera) {
			try {
		    	mCamera = Camera.open();
		    	hasCamera = true;
			} catch (RuntimeException e) {
		    	hasCamera = false;
				mCallback.cameraNotAvailable();
				return;
			}
	        try {
	           mCamera.setPreviewDisplay(mHolder);
	        } catch (IOException exception) {
	            mCamera.release();
	            mCamera = null;
	            hasCamera = false;
	        }
    	}
    }
    
    public void lightOff() {
    	if (hasSurface && hasCamera) {
	        mParameters.setFlashMode(Parameters.FLASH_MODE_OFF);
	        mCamera.setParameters(mParameters);
    	}
    }

    public void lightOn() {
    	if (this.isShown() && hasCamera) {
	        mParameters.setFlashMode(Parameters.FLASH_MODE_TORCH);
	        mCamera.setParameters(mParameters);
    	} else {
    		initCamera();
    	}
    }
    
    public boolean hasCamera() {
    	return hasCamera;
    }
    
    public void setCallback(Callback c) {
    	mCallback = c;
    	mActivity = (Activity) c;
    }
        
    public void releaseCamera() {
    	if (hasCamera) {
	        mCamera.stopPreview();
	        mCamera.release();
	        mCamera = null;
	        hasCamera = false;
    	}
    }
    
    public void startPreview() {
    	if (hasCamera) {
    		mCamera.startPreview();
    	}
    }
    
    public interface Callback {
    	public void cameraReady();
    	public void cameraNotAvailable();
    }
}