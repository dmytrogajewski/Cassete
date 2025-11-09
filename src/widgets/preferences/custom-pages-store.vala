/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Helper for storing and retrieving custom pages data from application settings.
 */

using Gee;
using GLib;

namespace Cassette {
    public class CustomPagesStore : Object {
        const string SETTINGS_KEY = "custom-pages";
        const string FIELD_SEPARATOR = "|";
        const string ARGS_SEPARATOR = ",";

        public static ArrayList<PageInfo> load () {
            var pages = new ArrayList<PageInfo> ();
            string[] records = Application.app_settings.get_strv (SETTINGS_KEY);

            foreach (var record in records) {
                var page_info = deserialize (record);
                if (page_info != null) {
                    pages.add (page_info);
                } else {
                    warning ("Failed to parse custom page record: %s", record);
                }
            }

            return pages;
        }

        public static void upsert (PageInfo page_info) {
            var pages = load ();

            for (int i = 0; i < pages.size; i++) {
                var existing = pages.get (i);
                if (existing.id == page_info.id) {
                    pages.set (i, page_info);
                    persist (pages);
                    return;
                }
            }

            pages.add (page_info);
            persist (pages);
        }

        public static bool remove (string page_id) {
            var pages = load ();

            for (int i = 0; i < pages.size; i++) {
                var page = pages.get (i);
                if (page.id == page_id) {
                    pages.remove_at (i);
                    persist (pages);
                    return true;
                }
            }

            return false;
        }

        public static PageInfo? try_get (string page_id) {
            var pages = load ();
            foreach (var page in pages) {
                if (page.id == page_id) {
                    return page;
                }
            }

            return null;
        }

        public static string serialize (PageInfo page_info) {
            var builder = new StringBuilder ();
            builder.append (encode_field (page_info.id));
            builder.append (FIELD_SEPARATOR);
            builder.append (encode_field (page_info.title));
            builder.append (FIELD_SEPARATOR);
            builder.append (encode_field (page_info.icon_name));
            builder.append (FIELD_SEPARATOR);
            builder.append (encode_field (page_info.view_type_name));
            builder.append (FIELD_SEPARATOR);
            builder.append (serialize_args (page_info.args));
            return builder.str;
        }

        static void persist (ArrayList<PageInfo> pages) {
            string[] records = new string[pages.size];

            for (int i = 0; i < pages.size; i++) {
                records[i] = serialize (pages.get (i));
            }

            Application.app_settings.set_strv (SETTINGS_KEY, records);
        }

        static PageInfo? deserialize (string record) {
            string[] fields = record.split (FIELD_SEPARATOR, 5);
            if (fields.length != 5) {
                return null;
            }

            var page_info = new PageInfo ();
            page_info.id = decode_field (fields[0]);
            page_info.title = decode_field (fields[1]);
            page_info.icon_name = decode_field (fields[2]);
            page_info.view_type_name = decode_field (fields[3]);
            page_info.args = deserialize_args (fields[4]);

            return page_info;
        }

        static string serialize_args (string?[] args) {
            if (args == null || args.length == 0) {
                return "";
            }

            string[] encoded_args = new string[args.length];
            for (int i = 0; i < args.length; i++) {
                encoded_args[i] = encode_field (args[i] ?? "");
            }

            return string.joinv (ARGS_SEPARATOR, encoded_args);
        }

        static string?[] deserialize_args (string data) {
            if (data.length == 0) {
                return {};
            }

            string[] parts = data.split (ARGS_SEPARATOR);
            string?[] args = new string?[parts.length];

            for (int i = 0; i < parts.length; i++) {
                string decoded = decode_field (parts[i]);
                if (decoded.length == 0) {
                    args[i] = null;
                } else {
                    args[i] = decoded;
                }
            }

            return args;
        }

        static string encode_field (string? field) {
            return Uri.escape_string (field ?? "", null, true);
        }

        static string decode_field (string field) {
            return Uri.unescape_string (field);
        }
    }
}

