!
function(a, b) {
	b(a, !0);
}(this, function(a, b) {

	(function() {

        function isWeiXin(){
            var ua = window.navigator.userAgent.toLowerCase();
            if(ua.match(/MicroMessenger/i) == 'micromessenger'){
                return true;
            }else{
                return false;
            }
        };

	    if (window.LeixunJSBridge || isWeiXin()) {
			// Android加上了这个if判断，如果当前window已经定义了LeixunJSBridge对象，不再重新加载
			// 避免重新初始化_callback_map等变量，导致之前的消息回调失败，返回cb404
			return;
	    };

	    var _nativeApiBridgeIframe,
	        _callback_count = 1000,
	        _callback_map = {},
	        _CUSTOM_PROTOCOL_SCHEME = 'native-server',
	        _API = 'api/',
	        _PARAMS = '?d=',
	        _CB = '&cb=';

	    function _createBridgeIframe(doc) {
	        _nativeApiBridgeIframe = doc.createElement('iframe');
	        _nativeApiBridgeIframe.id = '__LeixunJSBridgeIframe';
	        _nativeApiBridgeIframe.style.display = 'none';
	        doc.documentElement.appendChild(_nativeApiBridgeIframe);
	        return _nativeApiBridgeIframe;
	    }

	    function _call(func, params, callback) {
	        if (!func || typeof func !== 'string') {
	            return;
	        };
	        if (typeof params !== 'object') {
	            params = {};
	        };


	        if (typeof callback === 'function') {
		        var callbackID = (_callback_count++).toString();
		        _callback_map[callbackID] = callback;
		        _nativeApiBridgeIframe.src = _CUSTOM_PROTOCOL_SCHEME + '://' + _API + func + _PARAMS + encodeURIComponent(JSON.stringify(params)) + _CB + callbackID;
	        } else {
	        	_nativeApiBridgeIframe.src = _CUSTOM_PROTOCOL_SCHEME + '://' + _API + func + _PARAMS + encodeURIComponent(JSON.stringify(params));
	        };
	    }

	    function _on(callbackID, result) {
	    	var cb = _callback_map[callbackID];
	    	if (cb && typeof cb === 'function') {
	    		cb(result);
	    		delete _callback_map[callbackID];
	    	};
	    }

	    var __LeixunJSBridge = {
	        invoke:_call,
	        callback:_on
	    };

	    if (!window.LeixunJSBridge) {
	      window.LeixunJSBridge = __LeixunJSBridge;
	    }

	    var doc = document;
	    _createBridgeIframe(doc);

	})();

	function c(b, c, d) {
		if (a.LeixunJSBridge) {
			LeixunJSBridge.invoke(b, c, d);
		};
	}

	var C;
	if (!a.jLeixun) return  C = {
		//here api start

		pop: function() {
			c('pop', {

			});
		},

		alert: function(title, message, cancelButtonTitle, confirmButtonTitle, callback) {
			c('alert', {
				title: title,
				message: message,
				cancelButtonTitle: cancelButtonTitle,
				confirmButtonTitle: confirmButtonTitle
			}, callback);
		},

		push: function(code, d) {
			c('push', {
				code: code,
				d: d
			});
		},

		toRoot: function(tabIndex) {
			c('toRoot', {
				tabIndex: tabIndex
			});
		},

		openUrl: function(scheme) {
			c('openUrl', {
				scheme: scheme
			});
		},

		canOpenUrl: function(scheme, callback) {
			c('canOpenUrl', {
				scheme: scheme
			}, callback);
		},

		webTitle: function(title) {
			c('webTitle', {
				title: title
			});
		},

		toast: function(msg) {
			c('toast', {
				msg: msg
			});
		},

		shakeServicesEnable: function(callback) {
			c('shakeServicesEnable', {

			}, callback);
		},

		shakeServicesDisable: function(callback) {
			c('shakeServicesDisable', {

			}, callback);
		},

		shakeServicesAction: function(callback) {
			c('shakeServicesAction', {

			}, callback);
		},

		camera: function(callback) {
			c('camera', {

			}, callback);
		},

		screenshot: function(cutSizeWidth, cutSizeHeight, scale, callback) {
			c('screenshot', {
				cutSizeWidth: cutSizeWidth,
				cutSizeHeight: cutSizeHeight,
				scale: scale
			}, callback);
		},

		location: function(callback) {
			c('location', {

			}, callback);
		},

		login: function(callback) {
			c('login', {

			}, callback);
		},

		scheduleNotification: function(time, content, callback) {
			c('scheduleNotification', {
				time: time,
				content: content
			}, callback);
		},

		alipay: function(tradeNo, productName, productDescription, amount, notifyURL, scheme, callback) {
			c('alipay', {
				tradeNo: tradeNo,
				productName: productName,
				productDescription: productDescription,
				amount: amount,
				notifyURL: notifyURL,
				scheme: scheme
			}, callback);
		},

		share: function(shareUrl, shareTitle, shareImageUrl, shareDescription, showFlag, callback) {
			c('share', {
				shareUrl: shareUrl,
				shareTitle: shareTitle,
				shareImageUrl: shareImageUrl,
				shareDescription: shareDescription,
				showFlag: showFlag
			}, callback);
		},

		loadImage: function(imageUrl) {
			c('loadImage', {
				imageUrl: imageUrl
			});
		},

		setClipboardText: function(text) {
			c('setClipboardText', {
				text: text
			});
		},

		getClipboardText: function(callback) {
			c('getClipboardText', {

			}, callback);
		},

		//here api end
		dummy: function(undefined) {
			//just a placeholder
		}
	}, b && (a.lx = a.jLeixun = C), C
});
