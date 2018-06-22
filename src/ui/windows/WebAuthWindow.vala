using Gtk;
using GLib;
using WebKit;
using Soup;
using GameHub.Utils;

namespace GameHub.UI.Windows
{
	public class WebAuthWindow: Window
	{
		private WebView webview;

		private bool is_finished = false;

		public signal void finished(string url);
		public signal void canceled();

		public WebAuthWindow(string source, string url, string? success_url_prefix, string? success_cookie_name=null)
		{
			Object(transient_for: Windows.MainWindow.instance);
			
			title = source;
			var titlebar = new HeaderBar();
			titlebar.title = title;
			titlebar.show_close_button = true;
			set_titlebar(titlebar);
			
			set_size_request(640, 800);
			
			set_modal(true);
			
			webview = new WebView();
			
			var cookies_file = FSUtils.expand(FSUtils.Paths.Cache.Cookies);
			webview.web_context.get_cookie_manager().set_persistent_storage(cookies_file, CookiePersistentStorage.TEXT);
			
			webview.get_settings().enable_mediasource = true;
			webview.get_settings().enable_smooth_scrolling = true;
			
			webview.user_content_manager.add_style_sheet(new UserStyleSheet(".account-bbm-wrapper{background:#333 !important}", UserContentInjectedFrames.TOP_FRAME, UserStyleLevel.USER, null, null));

			webview.load_changed.connect(e => {
				var uri = webview.get_uri();
				titlebar.title = webview.title;
				titlebar.subtitle = uri.split("?")[0];
				titlebar.tooltip_text = uri;
				
				if(!is_finished && success_cookie_name != null)
				{					
					webview.web_context.get_cookie_manager().get_cookies.begin(uri, null, (obj, res) => {
						var cookies = webview.web_context.get_cookie_manager().get_cookies.end(res);
						foreach(var cookie in cookies)
						{
							if(!is_finished && cookie.name == success_cookie_name && !cookie.value.contains("\"") && (success_url_prefix == null || uri.has_prefix(success_url_prefix)))
							{								
								is_finished = true;
								finished(cookie.value);
								destroy();
								break;
							}
						}
					});
				}
				else if(!is_finished && success_url_prefix != null && uri.has_prefix(success_url_prefix))
				{
					is_finished = true;
					finished(uri.substring(success_url_prefix.length));
					destroy();
				}
			});

			webview.load_uri(url);
			
			add(webview);

			destroy.connect(() => { if(!is_finished) canceled(); });
		}
	}
}
