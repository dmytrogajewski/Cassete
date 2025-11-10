/*
 * Copyright (C) 2025 Vladimir Romanov <rirusha@altlinux.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace ApiBase {

    /**
     * A function for creating subcollections in the case of arrays in an array
     */
    public delegate void SubCollectionCreationFunc (out Gee.Traversable collection, Type element_type);

    internal const int GLOBAL_TIMEOUT = 30;

    internal bool type_is_valid (Type type_) {
        Type[] supported_base_types = {
            Type.STRING,
            Type.INT,
            Type.INT64,
            Type.DOUBLE,
            Type.BOOLEAN
        };

        Type[] supported_collections_types = {
            typeof (Gee.ArrayList),
            typeof (Gee.HashMap)
        };

        return type_ in supported_base_types ||
               type_ in supported_collections_types ||
               type_.is_enum () ||
               (type_.is_object () &&
                !(type_ in supported_collections_types) &&
                !find_generic (type_));
    }

    /**
     * Check GType on valid for using as Jsoner dataclass for
     * de/serialization. On fail will used {@link GLib.error}
     *
     * @param type_ type to check
     */
    public void check_type (Type type_) {
        Type[] supported_collections_types = {
            typeof (Gee.ArrayList),
            typeof (Gee.HashMap)
        };

        if (find_generic (type_)) {
            error ("DataObjects shouldn't be generics");
        }

        var class_ref = (ObjectClass) type_.class_ref ();
        foreach (var param_spec in class_ref.list_properties ()) {
            if (!type_is_valid (param_spec.value_type)) {
                error (
                    "Property %s::%s has unsupported value type (%s)",
                    param_spec.owner_type.name (),
                    param_spec.name,
                    param_spec.value_type.name ()
                );
            }
            if (param_spec.value_type in supported_collections_types) {
                var default_value = param_spec.get_default_value ();

                if (default_value == null) {
                    error (
                        "Property %s::%s must have default value (empty collection)",
                        param_spec.owner_type.name (),
                        param_spec.name
                    );
                }

                Type el_type;

                var obj = default_value.get_object ();
                if (obj is Gee.ArrayList) {
                    el_type = ((Gee.ArrayList) obj).element_type;
                } else if (obj is Gee.HashMap) {
                    var key_type = ((Gee.HashMap) obj).key_type;
                    el_type = ((Gee.HashMap) obj).value_type;

                    if (key_type != Type.STRING) {
                        error (
                            "Dict %s::%s has unsupported key type (%s)",
                            param_spec.owner_type.name (),
                            param_spec.name,
                            key_type.name ()
                        );
                    }
                } else {
                    assert_not_reached ();
                }

                if (!type_is_valid (el_type)) {
                    error (
                        "Collection %s::%s has unsupported element type (%s)",
                        param_spec.owner_type.name (),
                        param_spec.name,
                        el_type.name ()
                    );
                }
            }
        }
    }

    internal bool find_generic (Type type_) {
        var _type = new Gee.ArrayList<string> ();
        var _dup_func = new Gee.ArrayList<string> ();
        var _destroy_func = new Gee.ArrayList<string> ();

        var class_ref = (ObjectClass) type_.class_ref ();
        foreach (var param_spec in class_ref.list_properties ()) {
            if (param_spec.name.has_suffix ("-type")) {
                _type.add (param_spec.name);
            }
            if (param_spec.name.has_suffix ("-dup-func")) {
                _dup_func.add (param_spec.name);
            }
            if (param_spec.name.has_suffix ("-destroy-func")) {
                _destroy_func.add (param_spec.name);
            }
        }

        foreach (var t in _type) {
            if (
                @"$(t[0:t.length - 5])-dup-func" in _dup_func &&
                @"$(t[0:t.length - 5])-destroy-func" in _destroy_func
            ) {
                return true;
            }
        }

        return false;
    }

    internal BadStatusCodeError get_error (Soup.Status status_code, string error_response) {
        switch (status_code) {
            case Soup.Status.BAD_REQUEST:
                return new BadStatusCodeError.BAD_REQUEST (error_response);
            case Soup.Status.UNAUTHORIZED:
                return new BadStatusCodeError.UNAUTHORIZED (error_response);
            case Soup.Status.FORBIDDEN:
                return new BadStatusCodeError.FORBIDDEN (error_response);
            case Soup.Status.NOT_FOUND:
                return new BadStatusCodeError.NOT_FOUND (error_response);
            case Soup.Status.METHOD_NOT_ALLOWED:
                return new BadStatusCodeError.METHOD_NOT_ALLOWED (error_response);
            case Soup.Status.REQUEST_TIMEOUT:
                return new BadStatusCodeError.REQUEST_TIMEOUT (error_response);
            case Soup.Status.CONFLICT:
                return new BadStatusCodeError.CONFLICT (error_response);
            case Soup.Status.GONE:
                return new BadStatusCodeError.GONE (error_response);
            case Soup.Status.REQUEST_ENTITY_TOO_LARGE:
                return new BadStatusCodeError.PAYLOAD_TOO_LARGE (error_response);
            case Soup.Status.UNSUPPORTED_MEDIA_TYPE:
                return new BadStatusCodeError.UNSUPPORTED_MEDIA_TYPE (error_response);
            case 429:
                return new BadStatusCodeError.TOO_MANY_REQUESTS (error_response);
            case Soup.Status.INTERNAL_SERVER_ERROR:
                return new BadStatusCodeError.INTERNAL_SERVER_ERROR (error_response);
            case Soup.Status.NOT_IMPLEMENTED:
                return new BadStatusCodeError.NOT_IMPLEMENTED (error_response);
            case Soup.Status.BAD_GATEWAY:
                return new BadStatusCodeError.BAD_GATEWAY (error_response);
            case Soup.Status.SERVICE_UNAVAILABLE:
                return new BadStatusCodeError.SERVICE_UNAVAILABLE (error_response);
            case Soup.Status.GATEWAY_TIMEOUT:
                return new BadStatusCodeError.GATEWAY_TIMEOUT (error_response);
            default:
                return new BadStatusCodeError.UNKNOWN (status_code.to_string () + ": " + error_response);
        }
    }

    internal EnumClass get_enum_class (Type enum_type) {
        return (EnumClass) enum_type.class_ref ();
    }

    public int get_enum_by_nick (Type enum_type, string nick) {
        var enum_class = get_enum_class (enum_type);
        return enum_class.get_value_by_nick (snake2kebab (nick)).value;
    }

    public string get_enum_nick (Type enum_type, int enum_) {
        var enum_class = get_enum_class (enum_type);
        var enum_value = enum_class.get_value (enum_);

        return kebab2snake (enum_value.value_nick.down ());
    }

    public Datalist<T> hashmap_to_datalist<T> (Gee.HashMap<string, T> hash_map) {
        var dl = Datalist<T> ();

        foreach (var entry in hash_map) {
            dl.set_data (entry.key, entry.value);
        }

        return dl;
    }

    public Gee.HashMap<string, T> datalist_to_hashmap<T> (Datalist<T> datalist) {
        var hash_map = new Gee.HashMap<string, T> ();

        datalist.foreach ((key_quark, value) => {
            hash_map.set (key_quark.to_string (), value);
        });

        return hash_map;
    }

    /**
     * Delete all {@link char} from start and end of {@link string}
     *
     * @param str  string to be stripped
     * @param ch   char to strip
     *
     * @return     stripped string
     *
     * @since 0.1.0
     */
    public string strip (string str, char ch) {
        int start = 0;
        int end = str.length;

        while (str[start] == ch) {
            start++;
        }

        while (str[end - 1] == ch) {
            end--;
        }

        return str[start:end];
    }

    /**
     * Convert `сamelCase` to `kebab-case` string
     *
     * @param camel_string correct `сamelCase` string
     *
     * @return `kebab-case` string
     *
     * @since 0.1.0
     */
    public string camel2kebab (string camel_string) {
        var builder = new StringBuilder ();

        int i = 0;
        while (i < camel_string.length) {
            if (camel_string[i].isupper ()) {
                builder.append_c ('-');
                builder.append_c (camel_string[i].tolower ());
            } else {
                builder.append_c (camel_string[i]);
            }
            i += 1;
        }

        return builder.free_and_steal ();
    }

    /**
     * Convert `kebab-case` to `сamelCase` string
     *
     * @param kebab_string correct `kebab-case` string
     *
     * @return `сamelCase` string
     *
     * @since 0.1.0
     */
    public string kebab2camel (string kebab_string) {
        var builder = new StringBuilder ();

        int i = 0;
        while (i < kebab_string.length) {
            if (kebab_string[i] == '-') {
                i += 1;
                builder.append_c (kebab_string[i].toupper ());
            } else {
                builder.append_c (kebab_string[i]);
            }
            i += 1;
        }

        return builder.free_and_steal ();
    }

    /**
     * Convert `kebab-case` to `snake_case` string
     *
     * @param kebab_string correct `kebab-case` string
     *
     * @return `snake_case` string
     *
     * @since 0.1.0
     */
    public string kebab2snake (string kebab_string) {
        var builder = new StringBuilder ();

        int i = 0;
        while (i < kebab_string.length) {
            if (kebab_string[i] == '-') {
                builder.append_c ('_');
            } else {
                builder.append_c (kebab_string[i]);
            }
            i += 1;
        }

        return builder.free_and_steal ();
    }

    /**
     * Convert `snake_case` to `kebab-case` string
     *
     * @param snake_string correct `snake_case` string
     *
     * @return `kebab-case` string
     *
     * @since 0.1.0
     */
    public string snake2kebab (string snake_string) {
        var builder = new StringBuilder ();

        int i = 0;
        while (i < snake_string.length) {
            if (snake_string[i] == '_') {
                builder.append_c ('-');
            } else {
                builder.append_c (snake_string[i]);
            }
            i += 1;
        }

        return builder.free_and_steal ();
    }

    /**
     * Detect case from `str`
     *
     * @param str   String
     *
     * @return Case
     *
     * @since 3.0
     */
    public Case detect_case (string str) {
        for (uint i = 0; i < str.char_count (); i++) {
            unichar c = str.get_char (i);

            switch (c) {
                case '_':
                    return SNAKE;
                case '-':
                    return KEBAB;
            }

            if (c.isupper ()) {
                return CAMEL;
            }
        }

        return KEBAB;
    }

    /**
     * Convert any case string to kebab-case
     *
     * @param str   String
     *
     * @return Kebab string
     *
     * @since 3.0
     */
    public string any2kebab (string str) {
        var str_case = detect_case (str);

        switch (str_case) {
            case Case.CAMEL:
                return camel2kebab (str);
            case Case.SNAKE:
                return snake2kebab (str);
            case Case.KEBAB:
                return str;
            default:
                assert_not_reached ();
        }
    }
}
