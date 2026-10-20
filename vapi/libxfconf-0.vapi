/* Minimal libxfconf-0.vapi for NiceCalendar */
[CCode (cprefix = "Xfconf", lower_case_cprefix = "xfconf_")]
namespace Xfconf {
	[CCode (cheader_filename = "xfconf/xfconf.h")]
	public class Channel : GLib.Object {
		[CCode (has_construct_function = false)]
		public Channel (string channel_name);
		[CCode (cname = "xfconf_channel_get")]
		public static unowned Xfconf.Channel @get (string channel_name);
		public bool get_bool (string property, bool default_value);
		public double get_double (string property, double default_value);
		public int32 get_int (string property, int32 default_value);
		public bool get_property (string property, ref GLib.Value value);
		public string get_string (string property, string default_value);
		[CCode (array_length = false)]
		public unowned string[] get_string_list (string property);
		public uint32 get_uint (string property, uint32 default_value);
		public bool has_property (string property);
		public void reset_property (string property_base, bool recursive);
		public bool set_bool (string property, bool value);
		public bool set_double (string property, double value);
		public bool set_int (string property, int32 value);
		public bool set_property (string property, GLib.Value value);
		public bool set_string (string property, string value);
		public bool set_uint (string property, uint32 value);
		[CCode (cname = "xfconf_channel_get_properties")]
		public GLib.HashTable<string,GLib.Value?> get_properties (string property_base);
		public virtual signal void property_changed (string property, GLib.Value value);
	}
	[CCode (cheader_filename = "xfconf/xfconf.h", cprefix = "XFCONF_ERROR_")]
	public errordomain Error {
		UNKNOWN,
		CHANNEL_NOT_FOUND,
		PROPERTY_NOT_FOUND,
		READ_FAILURE,
		WRITE_FAILURE,
		PERMISSION_DENIED,
		INTERNAL_ERROR,
		NO_BACKEND,
		INVALID_PROPERTY,
		INVALID_CHANNEL
	}
	[CCode (cheader_filename = "xfconf/xfconf.h")]
	public static bool init () throws Xfconf.Error;
	[CCode (cheader_filename = "xfconf/xfconf.h")]
	public static void shutdown ();
}
