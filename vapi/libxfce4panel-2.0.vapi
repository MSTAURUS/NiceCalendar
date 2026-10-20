/* Minimal libxfce4panel-2.0.vapi for NiceCalendar */
[CCode (cprefix = "Xfce", lower_case_cprefix = "xfce_")]
namespace Xfce {
	[CCode (cheader_filename = "libxfce4panel/libxfce4panel.h")]
	public class PanelPlugin : Gtk.EventBox, Atk.Implementor, Gtk.Buildable {
		[CCode (has_construct_function = false)]
		protected PanelPlugin ();
		public void add_action_widget (Gtk.Widget widget);
		public void block_menu ();
		[NoWrapper]
		public virtual void @construct ();
		public unowned string get_arguments ();
		public unowned string get_comment ();
		public unowned string get_display_name ();
		public bool get_expand ();
		public bool get_locked ();
		public Gtk.Orientation get_orientation ();
		public unowned string get_property_base ();
		public int get_size ();
		public int get_unique_id ();
		public void menu_show_about ();
		public void menu_show_configure ();
		public void remove ();
		public void set_expand (bool expand);
		public void unblock_menu ();
		public string comment { get; construct; }
		public string display_name { get; construct; }
		public bool expand { get; set; }
		public string name { get; construct; }
		public Gtk.Orientation orientation { get; }
		public int size { get; }
		public int unique_id { get; construct; }
		public virtual signal void about ();
		public virtual signal void configure_plugin ();
		public virtual signal void free_data ();
		public virtual signal void orientation_changed (Gtk.Orientation orientation);
		public virtual signal void removed ();
		public virtual signal void save ();
		public virtual signal bool size_changed (int size);
		public signal void menu_show ();
	}
}
