/* Minimal libxfce4util-1.0.vapi */
[CCode (cprefix = "Xfce", lower_case_cprefix = "xfce_")]
namespace Xfce {
	[CCode (cheader_filename = "libxfce4util/libxfce4util.h")]
	public static void textdomain (string package, string localedir, string? encoding = null);
}
