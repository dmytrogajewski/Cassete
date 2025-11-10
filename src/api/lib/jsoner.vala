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

using Gee;

/**
 * Json helper for de/serialization
 *
 * @since 0.1.0
 */
public class ApiBase.Jsoner : Object {

    /**
     * Names case used for deserialization
     */
    public Case names_case { get; construct; }

    public Json.Node root { private get; construct; }

    /**
     * Performs initialization for deserialization. Accepts a json string. In case of
     * a parsing error
     *
     * @param json_string   Correct json string
     * @param sub_members   An array of names of json elements that need to be traversed
     *                      to the target node
     * @param names_case    Name case of element names in a json string
     *
     * @throws JsonError    Error with json or sub_members
     */
    public Jsoner (
        string json_string,
        string[]? sub_members = null,
        Case names_case = Case.AUTO
    ) throws JsonError {
        if (json_string.length < 1) {
            throw new JsonError.EMPTY ("Json string is empty");
        }

        Json.Node? node;
        try {
            node = Json.from_string (json_string);

        } catch (GLib.Error e) {
            throw new JsonError.INVALID ("'%s' is not correct json string".printf (json_string));
        }

        if (node == null) {
            throw new JsonError.EMPTY ("Json string is empty");
        }

        if (sub_members != null) {
            node = steps (node, sub_members);
        }

        debug (
            "Jsoner initted for deserialize with:\n%s",
            json_string
        );

        Object (root: node, names_case: names_case);
    }

    /**
     * Performs initialization for deserialization. Accepts a json string in the
     * form of bytes, the object {@link GLib.Bytes}. In case of a parsing error
     *
     * @param bytes         Json string in the form of bytes, the object {@link GLib.Bytes}
     * @param sub_members   An array of names of json elements that need to be traversed to the target node
     * @param names_case    Name case of element names in a json string
     *
     * @throws JsonError    Error with json or sub_members
     */
    public Jsoner.from_bytes (
        Bytes bytes,
        string[]? sub_members = null,
        Case names_case = Case.AUTO
    ) throws JsonError {
        if (bytes.length == 0) {
            throw new JsonError.EMPTY ("Json string is empty");
        }

        this.from_data (bytes.get_data (), sub_members, names_case);
    }

    /**
     * Performs initialization for deserialization. Accepts a json string in the form of bytes,
     * an {@link uint8} array. In case of a parsing error
     *
     * @param data         Json string in the form of bytes, {@link uint8} array
     * @param sub_members   An array of names of json elements that need to be traversed to the target node
     * @param names_case    Name case of element names in a json string
     *
     * @throws JsonError    Error with json or sub_members
     */
    public Jsoner.from_data (
        uint8[] data,
        string[]? sub_members = null,
        Case names_case = Case.AUTO
    ) throws JsonError {
        this ((string) data, sub_members, names_case);
    }

    static Json.Node? steps (
        Json.Node node,
        string[] sub_members
    ) throws JsonError {
        string has_members = "";

        foreach (string member_name in sub_members) {
            if (node.get_object ().has_member (member_name)) {
                node = node.get_object ().get_member (member_name);
                has_members += member_name + "-";

            } else {
                throw new JsonError.NO_MEMBER ("Json has no %s%s".printf (has_members, member_name));
            }
        }

        return node;
    }

    /////////////////
    // Serialize  //
    /////////////////

    /**
     * Serialize {@link GLib.Object} into a correct json string
     *
     * @param obj           {@link GLib.Object}
     * @param names_case    Name case of element names in a json string
     * @param pretty        Pretty print of json or not
     *
     * @return              Json string
     */
    public static string serialize (
        Object obj,
        Case names_case = Case.AUTO,
        bool pretty = false
    ) {
        if (names_case == Case.AUTO) {
            names_case = Case.KEBAB;
        }

        var builder = new Json.Builder ();

        if (obj is HashMap) {
            var dict = (HashMap) obj;
            serialize_hash_map (builder, dict, dict.value_type, names_case);
        } else {
            serialize_object (builder, obj, names_case);
        }

        var res = Json.to_string (builder.get_root (), pretty);

        debug (
            "Jsoner serialize complete:\n%s",
            res
        );

        return res;
    }

    static void serialize_array (
        Json.Builder builder,
        ArrayList array_list,
        Type element_type,
        Case names_case = Case.AUTO
    ) {
        if (names_case == Case.AUTO) {
            names_case = Case.KEBAB;
        }

        builder.begin_array ();

        if (element_type == typeof (ArrayList)) {
            var array_of_arrays = (ArrayList<ArrayList?>) array_list;

            if (array_of_arrays.size > 0) {
                Type sub_element_type = ((ArrayList<ArrayList?>) array_list)[0].element_type;

                foreach (var sub_array_list in (ArrayList<ArrayList?>) array_list) {
                    serialize_array (builder, sub_array_list, sub_element_type, names_case);
                }
            }

        } else if (element_type.is_object ()) {
            foreach (var obj in (ArrayList<Object>) array_list) {
                serialize_object (builder, obj, names_case);
            }

        } else {
            switch (element_type) {
                case Type.STRING:
                    foreach (var val in (ArrayList<string>) array_list) {
                        serialize_value (builder, val);
                    }
                    break;

                case Type.INT:
                    foreach (var val in (ArrayList<int>) array_list) {
                        serialize_value (builder, val);
                    }
                    break;

                case Type.INT64:
                    foreach (var val in (ArrayList<int64?>) array_list) {
                        var tval = Value (Type.INT64);
                        tval.set_int64 (val);
                        serialize_value (builder, tval);
                    }
                    break;

                case Type.DOUBLE:
                    foreach (var val in (ArrayList<double?>) array_list) {
                        var tval = Value (Type.DOUBLE);
                        tval.set_double (val);
                        serialize_value (builder, tval);
                    }
                    break;

                case Type.BOOLEAN:
                    foreach (var val in (ArrayList<bool>) array_list) {
                        serialize_value (builder, val);
                    }
                    break;
            }
        }
        builder.end_array ();
    }

    static void serialize_hash_map (
        Json.Builder builder,
        HashMap dict,
        Type element_type,
        Case names_case = Case.AUTO
    ) {
        if (names_case == Case.AUTO) {
            names_case = Case.KEBAB;
        }

        builder.begin_object ();

        if (element_type.is_object ()) {
            foreach (var entry in (HashMap<string, Object>) dict) {
                builder.set_member_name (entry.key);
                serialize_object (builder, entry.value, names_case);
            }

        } else {
            switch (element_type) {
                case Type.STRING:
                    foreach (var entry in (HashMap<string, string>) dict) {
                        builder.set_member_name (entry.key);
                        serialize_value (builder, entry.value);
                    }
                    break;

                case Type.INT:
                    foreach (var entry in (HashMap<string, int>) dict) {
                        builder.set_member_name (entry.key);
                        serialize_value (builder, entry.value);
                    }
                    break;

                case Type.INT64:
                    foreach (var entry in (HashMap<string, int64?>) dict) {
                        builder.set_member_name (entry.key);
                        var tval = Value (Type.INT64);
                        tval.set_int64 (entry.value);
                        serialize_value (builder, tval);
                    }
                    break;

                case Type.DOUBLE:
                    foreach (var entry in (HashMap<string, double?>) dict) {
                        builder.set_member_name (entry.key);
                        var tval = Value (Type.DOUBLE);
                        tval.set_double (entry.value);
                        serialize_value (builder, tval);
                    }
                    break;

                case Type.BOOLEAN:
                    foreach (var entry in (HashMap<string, bool>) dict) {
                        builder.set_member_name (entry.key);
                        serialize_value (builder, entry.value);
                    }
                    break;
            }
        }
        builder.end_object ();
    }

    static void serialize_object (
        Json.Builder builder,
        Object? api_obj,
        Case names_case = Case.AUTO
    ) {
        if (names_case == Case.AUTO) {
            names_case = Case.KEBAB;
        }

        if (api_obj == null) {
            builder.add_null_value ();

            return;
        }

        builder.begin_object ();
        var cls = (ObjectClass) api_obj.get_type ().class_ref ();

        foreach (ParamSpec property in cls.list_properties ()) {
            if (((property.flags & ParamFlags.READABLE) == 0) || ((property.flags & ParamFlags.WRITABLE) == 0)) {
                continue;
            }

            var prop_val = Value (property.value_type);
            api_obj.get_property (property.name, ref prop_val);

            // Skip null values for nullable string properties
            if (prop_val.type () == Type.NONE) {
                continue;
            }
            // Check for null string values (nullable strings)
            if (property.value_type.is_a (Type.STRING)) {
                var str_val = prop_val.get_string ();
                if (str_val == null) {
                    continue;
                }
            }

            switch (names_case) {
                case Case.CAMEL:
                    builder.set_member_name (kebab2camel (strip (property.name, '-')));
                    break;

                case Case.SNAKE:
                    builder.set_member_name (kebab2snake (strip (property.name, '-')));
                    break;

                case Case.KEBAB:
                    builder.set_member_name (strip (property.name, '-'));
                    break;

                default:
                    error ("Unknown case - %s", names_case.to_string ());
            }

            if (property.value_type == typeof (ArrayList)) {
                var array_list = (ArrayList) prop_val.get_object ();
                Type element_type = array_list.element_type;

                serialize_array (builder, array_list, element_type, names_case);

            } else if (property.value_type == typeof (HashMap)) {
                var hash_map = (HashMap) prop_val.get_object ();
                Type element_type = hash_map.value_type;

                serialize_hash_map (builder, hash_map, element_type, names_case);

            } else if (property.value_type.is_object ()) {
                serialize_object (builder, (Object) prop_val.get_object (), names_case);

            } else if (property.value_type.is_enum ()) {
                serialize_enum (builder, property.value_type, prop_val);

            } else {
                serialize_value (builder, prop_val);
            }
        }

        builder.end_object ();
    }

    static void serialize_enum (Json.Builder builder, Type enum_type, Value prop_val) {
        builder.add_string_value (get_enum_nick (enum_type, prop_val.get_enum ()));
    }

    static void serialize_value (Json.Builder builder, Value prop_val) {
        switch (prop_val.type ()) {
            case Type.INT:
                builder.add_int_value ((int64) prop_val.get_int ());
                break;

            case Type.INT64:
                builder.add_int_value (prop_val.get_int64 ());
                break;

            case Type.FLOAT:
                builder.add_double_value ((double) prop_val.get_float ());
                break;

            case Type.DOUBLE:
                builder.add_double_value (prop_val.get_double ());
                break;

            case Type.STRING:
                builder.add_string_value (prop_val.get_string ());
                break;

            case Type.BOOLEAN:
                builder.add_boolean_value (prop_val.get_boolean ());
                break;

            case Type.NONE:
                builder.add_null_value ();
                break;

            default:
                warning ("Unknown type for serialize - %s", prop_val.type ().name ());
                break;
        }
    }

    ///////////////////
    // Deserialize  //
    ///////////////////

    /**
     * Object creation method from json
     * via {@link Jsoner.deserialize_object}
     * Simple version for fast deserialization without
     * manual {@link Jsoner} instance creation
     *
     * @param json              Json string
     * @param sub_members       Sub members to 'steps'
     * @param names_case        Case of names in json
     * @param sub_creation_func Function for creating collection
     *                          objects with generics
     *
     * @return                  Deserialized object
     *
     * @throws JsonError        Error with json or sub_members
     *
     * @since 3.1
     */
    public static T simple_from_json<T> (
        string json,
        string[]? sub_members = null,
        Case names_case = Case.AUTO,
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws JsonError {
        var jsoner = new Jsoner (json, sub_members, names_case);
        return jsoner.deserialize_object<T> (sub_creation_func);
    }

    /**
     * Array creation method from json
     * via {@link Jsoner.deserialize_array}
     * Simple version for fast deserialization without
     * manual {@link Jsoner} instance creation
     *
     * @param json              Json string
     * @param sub_members       Sub members to 'steps'
     * @param names_case        Case of names in json
     * @param sub_creation_func Function for creating collection
     *                          objects with generics
     *
     * @return                  Deserialized array
     *
     * @throws JsonError        Error with json or sub_members
     *
     * @since 3.1
     */
    public static ArrayList<T> simple_array_from_json<T> (
        string json,
        string[]? sub_members = null,
        Case names_case = Case.AUTO,
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws JsonError {
        var jsoner = new Jsoner (json, sub_members, names_case);
        return jsoner.deserialize_array<T> (sub_creation_func);
    }

    /**
     * Dict creation method from json
     * via {@link Jsoner.deserialize_dict}
     * Simple version for fast deserialization without
     * manual {@link Jsoner} instance creation
     *
     * @param json              Json string
     * @param sub_members       Sub members to 'steps'
     * @param names_case        Case of names in json
     * @param sub_creation_func Function for creating collection
     *                          objects with generics
     *
     * @return                  Deserialized dict
     *
     * @throws JsonError        Error with json or sub_members
     *
     * @since 3.1
     */
    public static HashMap<string, T> simple_dict_from_json<T> (
        string json,
        string[]? sub_members = null,
        Case names_case = Case.AUTO,
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws JsonError {
        var jsoner = new Jsoner (json, sub_members, names_case);
        return jsoner.deserialize_dict<T> (sub_creation_func);
    }

    /**
     * Method for deserializing the {@link GLib.Object}
     *
     * @param sub_creation_func Function for creating collection
     *                          objects with generics
     *
     * @return  Deserialized object
     *
     * @throws JsonError    Error with json string
     *
     * @since 3.0
     */
    public T deserialize_object<T> (
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws JsonError {
        return deserialize_object_by_type (typeof (T), sub_creation_func);
    }

    /**
     * Method for deserializing the {@link GLib.Object} with {@link GLib.Type}
     *
     * @param sub_creation_func Function for creating collection
     *                          objects with generics
     * @param obj_type          Type of objects
     *
     * @return  Deserialized object
     *
     * @throws JsonError    Error with json string
     *
     * @since 3.0
     */
    public Object deserialize_object_by_type (
        GLib.Type obj_type,
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws JsonError {
        var obj = Object.new (obj_type);

        deserialize_object_into (obj, sub_creation_func);

        return obj;
    }

    internal Object deserialize_object_by_type_real (
        GLib.Type obj_type,
        Json.Node? node = null,
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws JsonError {
        var obj = Object.new (obj_type);

        deserialize_object_into_real (obj, node, sub_creation_func);

        return obj;
    }

    /**
     * Method for deserializing into existing object
     *
     * @param obj               Object
     * @param sub_creation_func Function for creating collection
     *                          objects with generics
     *
     * @throws JsonError    Error with json string
     *
     * @since 3.0
     */
    public void deserialize_object_into (
        Object obj,
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws JsonError {
        deserialize_object_into_real (obj, null, sub_creation_func);
    }

    internal void deserialize_object_into_real (
        Object obj,
        Json.Node? node = null,
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws JsonError {
        if (node == null) {
            node = root;
        }

        if (node.get_node_type () != Json.NodeType.OBJECT) {
            warning ("Wrong type: expected %s, got %s",
                Json.NodeType.OBJECT.to_string (),
                node.get_node_type ().to_string ()
            );
            throw new JsonError.WRONG_TYPE ("Node isn't object");
        }

        obj.freeze_notify ();

        var obj_type = obj.get_type ();
        var class_ref = (ObjectClass) obj_type.class_ref ();
        ParamSpec[] properties = class_ref.list_properties ();

        var props_data = new Gee.HashMap<string, ParamSpec> ();
        foreach (ParamSpec property in properties) {
            if ((property.flags & ParamFlags.WRITABLE) == 0) {
                continue;
            }

            var stripped_name = strip (property.name, '-');
            if (props_data.has_key (stripped_name)) {
                warning ("Detected property collision");
            }
            props_data[strip (property.name, '-')] = property;
        }

        foreach (var member_name in node.get_object ().get_members ()) {
            string kebabbed_member_name;
            switch (names_case) {
                case Case.CAMEL:
                    kebabbed_member_name = camel2kebab (member_name);
                    break;
                case Case.SNAKE:
                    kebabbed_member_name = snake2kebab (member_name);
                    break;
                case Case.KEBAB:
                    kebabbed_member_name = member_name;
                    break;
                case Case.AUTO:
                    kebabbed_member_name = any2kebab (member_name);
                    break;
                default:
                    assert_not_reached ();
            }

            if (!props_data.has_key (kebabbed_member_name)) {
                var unknown_fields = Environment.get_variable ("API_BASE_UNKNOWN_FIELDS");
                if (unknown_fields != null) {
                    warning (
                        "The object '%s' does not have a property '%s' corresponding to the json field '%s'",
                        obj_type.name (),
                        kebabbed_member_name,
                        member_name
                    );
                }
                continue;
            }

            var property = props_data[kebabbed_member_name];

            Type prop_type = property.value_type;

            var sub_node = node.get_object ().get_member (member_name);

            switch (sub_node.get_node_type ()) {
                case Json.NodeType.ARRAY:
                    var arrayval = Value (prop_type);
                    obj.get_property (property.name, ref arrayval);
                    ArrayList array_list = (Gee.ArrayList) arrayval.get_object ();

                    deserialize_array_into_real (array_list, sub_node, sub_creation_func);
                    obj.set_property (
                        property.name,
                        array_list
                    );
                    break;

                case Json.NodeType.OBJECT:
                    if (prop_type.is_a (typeof (HashMap))) {
                        var dictval = Value (prop_type);
                        obj.get_property (property.name, ref dictval);
                        HashMap hash_map = (HashMap) dictval.get_object ();

                        deserialize_dict_into_real (hash_map, sub_node, sub_creation_func);
                        obj.set_property (
                            property.name,
                            hash_map
                        );
                        break;

                    } else {
                        obj.set_property (
                            property.name,
                            deserialize_object_by_type_real (prop_type, sub_node, sub_creation_func)
                        );
                    }

                    break;

                case Json.NodeType.VALUE:
                    var val = deserialize_value_real (sub_node);
                    if (prop_type.is_enum ()) {
                        obj.set_property (
                            property.name,
                            get_enum_by_nick (prop_type, val.get_string ())
                        );

                    } else {
                        var new_val = Value (prop_type);
                        if (!val.transform (ref new_val)) {
                            warning (
                                "Failed to transform %s to %s of %s::%s",
                                val.type_name (),
                                prop_type.name (),
                                obj_type.name (),
                                property.name
                            );
                        }
                        obj.set_property (
                            property.name,
                            new_val
                        );
                    }
                    break;

                case Json.NodeType.NULL:
                    obj.set_property (
                        property.name,
                        Value (prop_type)
                    );
                    break;
            }
        }

        obj.thaw_notify ();
    }

    /**
     * Method for deserializing the {@link GLib.Value}
     *
     * @return deserialized value
     *
     * @throws JsonError    Error with json string
     */
    public Value deserialize_value () throws JsonError {
        return deserialize_value_real (null);
    }

    internal Value deserialize_value_real (Json.Node? node = null) throws JsonError {
        if (node == null) {
            node = root;
        }

        if (node.get_node_type () != Json.NodeType.VALUE) {
            warning ("Wrong type: expected %s, got %s",
                Json.NodeType.VALUE.to_string (),
                node.get_node_type ().to_string ()
            );

            throw new JsonError.WRONG_TYPE ("Node isn't value");
        }

        return node.get_value ();
    }

    /**
     * Method for deserializing the {@link Gee.ArrayList}
     *
     * @param sub_creation_func A function for creating subsets in the case of arrays in an array
     *
     * @throws JsonError    Error with json string
     *
     * @since 3.1
     */
    public ArrayList<T> deserialize_array<T> (
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws JsonError {
        var array_list = new ArrayList<T> ();
        deserialize_array_into (array_list, sub_creation_func);
        return array_list;
    }

    /**
     * Method for deserializing the {@link Gee.ArrayList}
     *
     * @param array_list        Array
     * @param sub_creation_func A function for creating subsets in the case of arrays in an array
     *
     * @throws JsonError    Error with json string
     */
    public void deserialize_array_into (
        ArrayList array_list,
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws JsonError {
        deserialize_array_into_real (array_list, null, sub_creation_func);
    }

    internal void deserialize_array_into_real (
        ArrayList array_list,
        Json.Node? node = null,
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws JsonError {
        if (node == null) {
            node = root;
        }

        if (node.get_node_type () != Json.NodeType.ARRAY) {
            warning ("Wrong type: expected %s, got %s",
                Json.NodeType.ARRAY.to_string (),
                node.get_node_type ().to_string ()
            );
            throw new JsonError.WRONG_TYPE ("Node isn't array");
        }

        var jarray = node.get_array ();

        if (array_list.element_type == typeof (ArrayList)) {
            var narray_list = array_list as ArrayList<ArrayList>;

            assert (narray_list.size != 0);

            Type sub_element_type = narray_list[0].element_type;

            foreach (var sub_node in jarray.get_elements ()) {
                Traversable new_col;

                if (sub_creation_func != null) {
                    sub_creation_func (out new_col, sub_element_type);

                } else {
                    error ("Creation func is null");
                }

                assert (new_col is ArrayList);
                var new_array_list = (ArrayList) new_col;

                try {
                    deserialize_array_into_real (new_array_list, sub_node, sub_creation_func);
                    narray_list.add (new_array_list);
                } catch (JsonError e) {}
            }

            narray_list.remove (narray_list[0]);
        } else if (array_list.element_type.is_object ()) {
            array_list.clear ();
            var narray_list = array_list as ArrayList<Object>;

            foreach (var sub_node in jarray.get_elements ()) {
                try {
                    narray_list.add (deserialize_object_by_type_real (narray_list.element_type, sub_node));
                } catch (JsonError e) {}
            }

        } else {
            array_list.clear ();

            foreach (var sub_node in jarray.get_elements ()) {
                var dval = deserialize_value_real (sub_node);
                var new_val = Value (array_list.element_type);
                dval.transform (ref new_val);

                switch (array_list.element_type) {
                    case Type.STRING:
                        var narray_list = array_list as ArrayList<string>;
                        narray_list.add (new_val.get_string ());
                        break;

                    case Type.INT:
                        var narray_list = array_list as ArrayList<int>;
                        narray_list.add (new_val.get_int ());
                        break;

                    case Type.INT64:
                        var narray_list = array_list as ArrayList<int64?>;
                        narray_list.add (new_val.get_int64 ());
                        break;

                    case Type.DOUBLE:
                        var narray_list = array_list as ArrayList<double?>;
                        narray_list.add (new_val.get_double ());
                        break;

                    case Type.BOOLEAN:
                        var narray_list = array_list as ArrayList<bool>;
                        narray_list.add (new_val.get_boolean ());
                        break;

                    default:
                        warning ("Unknown type of element of array - %s",
                            array_list.element_type.name ()
                        );
                        break;
                }
            }
        }
    }

    /**
     * Method for deserializing the {@link Gee.HashMap}
     *
     * @param sub_creation_func A function for creating subsets in the case of arrays in an array
     *
     * @throws JsonError    Error with json string
     *
     * @since 3.1
     */
    public HashMap<string, T> deserialize_dict<T> (
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws JsonError {
        var dict = new HashMap<string, T> ();
        deserialize_dict_into (dict, sub_creation_func);
        return dict;
    }

    /**
     * Method for deserializing the {@link Gee.HashMap}
     *
     * @param dict              Dict
     * @param sub_creation_func A function for creating subsets in the case of arrays in an array
     *
     * @throws JsonError    Error with json string
     *
     * @since 3.0
     */
    public void deserialize_dict_into (
        HashMap dict,
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws JsonError {
        deserialize_dict_into_real (dict, null, sub_creation_func);
    }

    internal void deserialize_dict_into_real (
        HashMap dict,
        Json.Node? node = null,
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws JsonError {
        if (node == null) {
            node = root;
        }

        if (node.get_node_type () != Json.NodeType.OBJECT) {
            warning ("Wrong type: expected %s, got %s",
                Json.NodeType.OBJECT.to_string (),
                node.get_node_type ().to_string ()
            );
            throw new JsonError.WRONG_TYPE ("Node isn't object");
        }

        if (dict.key_type != Type.STRING) {
            error ("HashMap can only have string as key type");
        }

        var jobject = node.get_object ();

        if (dict.value_type.is_object ()) {
            dict.clear ();
            var narray_list = dict as HashMap<string, Object>;

            foreach (var member_name in jobject.get_members ()) {
                var sub_node = jobject.get_member (member_name);

                try {
                    narray_list[member_name] = deserialize_object_by_type_real (
                        narray_list.value_type,
                        sub_node,
                        sub_creation_func
                    );
                } catch (JsonError e) {}
            }

        } else {
            dict.clear ();

            foreach (var member_name in jobject.get_members ()) {
                var sub_node = jobject.get_member (member_name);
                var dval = deserialize_value_real (sub_node);
                var new_val = Value (dict.value_type);
                dval.transform (ref new_val);

                switch (dict.value_type) {
                    case Type.STRING:
                        var narray_list = dict as HashMap<string, string>;
                        narray_list[member_name] = new_val.get_string ();
                        break;

                    case Type.INT:
                        var narray_list = dict as HashMap<string, int>;
                        narray_list[member_name] = new_val.get_int ();
                        break;

                    case Type.INT64:
                        var narray_list = dict as HashMap<string, int64?>;
                        narray_list[member_name] = new_val.get_int64 ();
                        break;

                    case Type.DOUBLE:
                        var narray_list = dict as HashMap<string, double?>;
                        narray_list[member_name] = new_val.get_double ();
                        break;

                    case Type.BOOLEAN:
                        var narray_list = dict as HashMap<string, bool>;
                        narray_list[member_name] = new_val.get_boolean ();
                        break;

                    default:
                        warning ("Unknown type of element of hashmap - %s",
                            dict.value_type.name ()
                        );
                        break;
                }
            }
        }
    }

    // ASYNC

    /**
     * Asynchronous version of method {@link serialize}
     */
    public static async string serialize_async (
        Object obj,
        Case names_case = Case.AUTO,
        bool pretty = false
    ) {
        if (names_case == Case.AUTO) {
            names_case = Case.KEBAB;
        }

        var thread = new Thread<string> (null, () => {
            var result = serialize (obj, names_case, pretty);

            Idle.add (serialize_async.callback);
            return result;
        });

        yield;

        return thread.join ();
    }

    /**
     * Asynchronous version of method {@link simple_from_json_async}
     *
     * @param json              Json string
     * @param sub_members       Sub members to 'steps'
     * @param names_case        Case of names in json
     * @param sub_creation_func Function for creating collection
     *                          objects with generics
     *
     * @return                  Deserialized object
     *
     * @throws JsonError        Error with json or sub_members
     *
     * @since 3.1
     */
    public async static T simple_from_json_async<T> (
        string json,
        string[]? sub_members = null,
        Case names_case = Case.AUTO,
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws JsonError {
        JsonError? error = null;

        var thread = new Thread<T?> (null, () => {
            T? result = null;

            try {
                result = simple_from_json<T> (
                    json,
                    sub_members,
                    names_case,
                    sub_creation_func
                );
            } catch (JsonError e) {
                error = e;
            }

            Idle.add (simple_from_json_async.callback);
            return result;
        });

        yield;

        if (error != null) {
            throw error;
        }

        return thread.join ();
    }

    /**
     * Asynchronous version of method {@link simple_array_from_json_async}
     *
     * @param json              Json string
     * @param sub_members       Sub members to 'steps'
     * @param names_case        Case of names in json
     * @param sub_creation_func Function for creating collection
     *                          objects with generics
     *
     * @return                  Deserialized array
     *
     * @throws JsonError        Error with json or sub_members
     *
     * @since 3.1
     */
    public async static ArrayList<T> simple_array_from_json_async<T> (
        string json,
        string[]? sub_members = null,
        Case names_case = Case.AUTO,
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws JsonError {
        JsonError? error = null;

        var thread = new Thread<ArrayList<T>?> (null, () => {
            ArrayList<T>? result = null;

            try {
                result = simple_array_from_json<T> (
                    json,
                    sub_members,
                    names_case,
                    sub_creation_func
                );
            } catch (JsonError e) {
                error = e;
            }

            Idle.add (simple_array_from_json_async.callback);
            return result;
        });

        yield;

        if (error != null) {
            throw error;
        }

        return thread.join ();
    }

    /**
     * Asynchronous version of method {@link simple_dict_from_json_async}
     *
     * @param json              Json string
     * @param sub_members       Sub members to 'steps'
     * @param names_case        Case of names in json
     * @param sub_creation_func Function for creating collection
     *                          objects with generics
     *
     * @return                  Deserialized dict
     *
     * @throws JsonError        Error with json or sub_members
     *
     * @since 3.1
     */
    public async static HashMap<string, T> simple_dict_from_json_async<T> (
        string json,
        string[]? sub_members = null,
        Case names_case = Case.AUTO,
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws JsonError {
        JsonError? error = null;

        var thread = new Thread<HashMap<string, T>?> (null, () => {
            HashMap<string, T>? result = null;

            try {
                result = simple_dict_from_json<T> (
                    json,
                    sub_members,
                    names_case,
                    sub_creation_func
                );
            } catch (JsonError e) {
                error = e;
            }

            Idle.add (simple_dict_from_json_async.callback);
            return result;
        });

        yield;

        if (error != null) {
            throw error;
        }

        return thread.join ();
    }

    /**
     * Asynchronous version of method {@link deserialize_object}
     *
     * @param sub_creation_func Function for creating collection
     *                          objects with generics
     *
     * @return  Deserialized object
     *
     * @throws JsonError    Error with json string
     *
     * @since 3.0
     */
    public async T deserialize_object_async<T> (
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws JsonError {
        JsonError? error = null;

        var thread = new Thread<T?> (null, () => {
            T? result = null;

            try {
                result = deserialize_object<T> (sub_creation_func);
            } catch (JsonError e) {
                error = e;
            }

            Idle.add (deserialize_object_async.callback);
            return result;
        });

        yield;

        if (error != null) {
            throw error;
        }

        return thread.join ();
    }

    /**
     * Asynchronous version of method {@link deserialize_object_by_type}
     *
     * @throws JsonError    Error with json string
     */
    public async Object deserialize_object_by_type_async (
        GLib.Type obj_type,
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws JsonError {
        JsonError? error = null;

        var thread = new Thread<Object?> (null, () => {
            Object? result = null;

            try {
                result = deserialize_object_by_type (obj_type, sub_creation_func);
            } catch (JsonError e) {
                error = e;
            }

            Idle.add (deserialize_object_by_type_async.callback);
            return result;
        });

        yield;

        if (error != null) {
            throw error;
        }

        return thread.join ();
    }

    /**
     * Asynchronous version of method {@link deserialize_object_into}
     *
     * @throws JsonError    Error with json string
     */
    public async void deserialize_object_into_async (
        Object obj,
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws JsonError {
        JsonError? error = null;

        var thread = new Thread<void> (null, () => {
            try {
                deserialize_object_into (obj, sub_creation_func);
            } catch (JsonError e) {
                error = e;
            }

            Idle.add (deserialize_object_into_async.callback);
            return;
        });

        yield;

        if (error != null) {
            throw error;
        }

        thread.join ();
    }

    /**
     * Asynchronous version of method {@link deserialize_array}
     *
     * @param sub_creation_func A function for creating subsets in the case of arrays in an array
     *
     * @throws JsonError    Error with json string
     *
     * @since 3.1
     */
    public async ArrayList<T> deserialize_array_async<T> (
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws JsonError {
        JsonError? error = null;

        var thread = new Thread<ArrayList<T>?> (null, () => {
            ArrayList<T>? result = null;

            try {
                result = deserialize_array (sub_creation_func);
            } catch (JsonError e) {
                error = e;
            }

            Idle.add (deserialize_array_async.callback);
            return result;
        });

        yield;

        if (error != null) {
            throw error;
        }

        return thread.join ();
    }

    /**
     * Asynchronous version of method {@link deserialize_array_into}
     *
     * @param array_list        Array
     * @param sub_creation_func A function for creating subsets in the case of arrays in an array
     *
     * @throws JsonError    Error with json string
     *
     * @since 3.0
     */
    public async void deserialize_array_into_async (
        ArrayList array_list,
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws JsonError {
        JsonError? error = null;

        var thread = new Thread<void> (null, () => {
            try {
                deserialize_array_into (array_list, sub_creation_func);
            } catch (JsonError e) {
                error = e;
            }

            Idle.add (deserialize_array_into_async.callback);
            return;
        });

        yield;

        if (error != null) {
            throw error;
        }

        thread.join ();
    }

    /**
     * Asynchronous version of method {@link deserialize_dict}
     *
     * @param sub_creation_func A function for creating subsets in the case of arrays in an array
     *
     * @throws JsonError    Error with json string
     *
     * @since 3.1
     */
    public async HashMap<string, T> deserialize_dict_async<T> (
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws JsonError {
        JsonError? error = null;

        var thread = new Thread<HashMap<string, T>?> (null, () => {
            HashMap<string, T>? result = null;

            try {
                result = deserialize_dict (sub_creation_func);
            } catch (JsonError e) {
                error = e;
            }

            Idle.add (deserialize_dict_async.callback);
            return result;
        });

        yield;

        if (error != null) {
            throw error;
        }

        return thread.join ();
    }

    /**
     * Asynchronous version of method {@link deserialize_dict_into}
     *
     * @param dict              Dict
     * @param sub_creation_func A function for creating subsets in the case of arrays in an array
     *
     * @throws JsonError    Error with json string
     *
     * @since 3.1
     */
    public async void deserialize_dict_into_async (
        HashMap dict,
        SubCollectionCreationFunc? sub_creation_func = null
    ) throws JsonError {
        JsonError? error = null;

        var thread = new Thread<void> (null, () => {
            try {
                deserialize_dict_into (dict, sub_creation_func);
            } catch (JsonError e) {
                error = e;
            }

            Idle.add (deserialize_dict_into_async.callback);
            return;
        });

        yield;

        if (error != null) {
            throw error;
        }

        thread.join ();
    }
}
