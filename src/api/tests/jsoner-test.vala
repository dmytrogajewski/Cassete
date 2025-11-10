// ind-check=skip-file
// vala-lint=skip-file

using ApiBase;

const string STRING_VAL_NAME = "string-val";
const string STRING_VAL = "test";
const string INT64_VAL_NAME = "int64-val";
const int64 INT64_VAL = 1234;
const string INT_VAL_NAME = "int-val";
const int INT_VAL = 1234;
const string DOUBLE_VAL_NAME = "double-val";
const double DOUBLE_VAL = 45.1;
const string BOOL_VAL_NAME = "bool-val";
const bool BOOL_VAL = true;
const string ENUM_VAL_NAME = "enum-val";
const TestEnum ENUM_VAL = VALUE_2;
const string TYPE__NAME = "type";
const string TYPE_ = "some text";
const string ERROR_CODE_NAME = "error-code";
const int ERROR_CODE = 6;

public class ValuesData : DataObject {
    public string string_val { get; set; }
    public int64 int64_val { get; set; }
    public int int_val { get; set; }
    public double double_val { get; set; }
    public bool bool_val { get; set; }
    public TestEnum enum_val { get; set; }

    // Strange names

    // Property with 'type' name cannot exists
    public string type_ { get; set; }
    // The issue is lost, but there was an error about incorrect deserialization of "error_code"
    public int error_code { get; set; }
}

public class TestObjectString : DataObject {
    public string? value { get; set; }
}

public class TestObjectStringCamel : Object {
    public string string_value { get; set; }
}

public class TestObjectStringCamelW : Object {
    public string string_value_ { get; set; }
}

public class TestObjectInt64 : Object {
    public int64 value { get; set; }
}

public class TestObjectInt : DataObject {
    public int value { get; set; }
}

public class TestObjectBool : Object {
    public bool value { get; set; }
}

public class TestObjectDouble : DataObject {
    public double value { get; set; }
}

public enum TestEnum {
    VALUE_1,
    VALUE_2,
}

public class TestObjectEnum : Object {
    public TestEnum value { get; set; }
}

public class SimpleObject : DataObject {
    public string string_value { get; set; }
    public int int_value { get; set; }
    public bool bool_value { get; set; }
}

public class TestObjectArrayString : DataObject {
    public Gee.ArrayList<string> value { get; set; default = new Gee.ArrayList<string> (); }
}

public class TestObjectDictString : DataObject {
    public Gee.HashMap<string, string> value { get; set; default = new Gee.HashMap<string, string> (); }
}

public class TestObjectArrayObject : DataObject {
    public Gee.ArrayList<SimpleObject> value { get; set; default = new Gee.ArrayList<SimpleObject> (); }
}

public class TestObjectArrayArray : Object {
    public Gee.ArrayList<Gee.ArrayList<SimpleObject>> value { get; set; default = new Gee.ArrayList<Gee.ArrayList<SimpleObject>> (); }
}

public class TestObjectAlbum : Object {
    public Gee.ArrayList<Gee.ArrayList<TestObjectInt>> value { get; set; default = new Gee.ArrayList<Gee.ArrayList<TestObjectInt>> (); }

    construct {
        value.add (new Gee.ArrayList<TestObjectInt> ());
    }
}

string get_name_with_c (string name, ApiBase.Case c) {
    switch (c) {
        case KEBAB:
            return name;
        case SNAKE:
            return kebab2snake (name);
        case CAMEL:
            return kebab2camel (name);
        default:
            assert_not_reached ();
    }
}

string get_exp_json (ApiBase.Case c) {
    return "{%s}".printf (string.joinv (",", {
        @"\"$(get_name_with_c (STRING_VAL_NAME, c))\":\"$STRING_VAL\"",
        @"\"$(get_name_with_c (INT64_VAL_NAME, c))\":$INT64_VAL",
        @"\"$(get_name_with_c (INT_VAL_NAME, c))\":$INT_VAL",
        @"\"$(get_name_with_c (DOUBLE_VAL_NAME, c))\":$DOUBLE_VAL",
        @"\"$(get_name_with_c (BOOL_VAL_NAME, c))\":$BOOL_VAL",
        @"\"$(get_name_with_c (ENUM_VAL_NAME, c))\":\"$(get_enum_nick (typeof (TestEnum), ENUM_VAL))\"",
        @"\"$(get_name_with_c (TYPE__NAME, c))\":\"$TYPE_\"",
        @"\"$(get_name_with_c (ERROR_CODE_NAME, c))\":$ERROR_CODE",
    }));
}

public int main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/jsoner/serialize/values", () => {
        Case[] cases = {KEBAB, SNAKE, CAMEL};
        foreach (var c in cases) {
            var test_object = new ValuesData ();

            test_object.string_val = STRING_VAL;
            test_object.int64_val = INT64_VAL;
            test_object.int_val = INT_VAL;
            test_object.double_val = DOUBLE_VAL;
            test_object.bool_val = BOOL_VAL;
            test_object.enum_val = ENUM_VAL;
            test_object.type_ = TYPE_;
            test_object.error_code = ERROR_CODE;

            string expectation = get_exp_json (c);
            var result = Jsoner.serialize (test_object, c);

            if (result != expectation) {
                Test.fail_printf (result + " != " + expectation);
            }
        }
    });

    Test.add_func ("/jsoner/deserialize/values", () => {
        Case[] cases = {KEBAB, SNAKE, CAMEL};
        foreach (var c in cases) {
            string json = get_exp_json (c);

            ValuesData result;

            try {
                result = Jsoner.simple_from_json<ValuesData> (json, null, c);
            } catch (Error e) {
                Test.fail_printf (e.message);
                return;
            }

            if (result.string_val != STRING_VAL) {
                Test.fail_printf (@"$(result.string_val) != $(STRING_VAL)");
            }
            if (result.int64_val != INT64_VAL) {
                Test.fail_printf (@"$(result.int64_val) != $(INT64_VAL)");
            }
            if (result.int_val != INT64_VAL) {
                Test.fail_printf (@"$(result.int_val) != $(INT64_VAL)");
            }
            if (result.double_val != DOUBLE_VAL) {
                Test.fail_printf (@"$(result.double_val) != $(DOUBLE_VAL)");
            }
            if (result.bool_val != BOOL_VAL) {
                Test.fail_printf (@"$(result.bool_val) != $(BOOL_VAL)");
            }
            if (result.enum_val != ENUM_VAL) {
                Test.fail_printf (@"$(result.enum_val) != $(ENUM_VAL)");
            }
            if (result.type_ != TYPE_) {
                Test.fail_printf (@"$(result.type_) != $(TYPE_)");
            }
            if (result.error_code != ERROR_CODE) {
                Test.fail_printf (@"$(result.type_) != $(ERROR_CODE)");
            }
        }
    });

    Test.add_func ("/jsoner/serialize/null", () => {
        var test_object = new TestObjectString ();
        test_object.value = null;

        string expectation = "{\"value\":null}";
        message ("kek");
        string result = Jsoner.serialize (test_object);

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/jsoner/serialize/yam_obj", () => {
        var test_object = new SimpleObject ();
        test_object.string_value = "test";
        test_object.int_value = 42;
        test_object.bool_value = true;

        string expectation = "{\"string-value\":\"test\",\"int-value\":42,\"bool-value\":true}";
        string result = Jsoner.serialize (test_object);

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/jsoner/deserialize/bad-json", () => {
        var json = "{\"string-value\":\"test\",\"int_value\":42,\"boolValue\":true}";

        SimpleObject obj;
        try {
            obj = Jsoner.simple_from_json<SimpleObject> (json);
        } catch (JsonError e) {
            Test.skip (e.domain.to_string () + ": " + e.message);
            return;
        }

        if (
            obj.string_value != "test" ||
            obj.int_value != 42 ||
            obj.bool_value != true
        ) {
            Test.fail ();
        }
    });

    Test.add_func ("/jsoner/serialize/array/string", () => {
        var test_object = new TestObjectArrayString ();
        test_object.value.add ("everything that lives is designed to end");
        test_object.value.add ("we are perpetually trapped in a neverending spyral of life and death");
        test_object.value.add ("is this a curse?");
        test_object.value.add ("or some kind of punishment?");
        test_object.value.add ("i often thinking about the god who blessed us with this cryptic puzzle");
        test_object.value.add ("and wonder if we'll ever have a chance to kill him");

        string expectation = "{\"value\":[\"everything that lives is designed to end\",\"we are perpetually trapped in a neverending spyral of life and death\",\"is this a curse?\",\"or some kind of punishment?\",\"i often thinking about the god who blessed us with this cryptic puzzle\",\"and wonder if we'll ever have a chance to kill him\"]}";
        string result = Jsoner.serialize (test_object);

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/jsoner/serialize/dict/string", () => {
        var expected_json = "{\"value\":{\"kekw\":\"yes\",\"kek\":\"no\"}}";

        var obj = new TestObjectDictString ();
        obj.value.set ("kekw", "yes");
        obj.value.set ("kek", "no");

        var result = obj.to_json ();

        if (result != expected_json) {
            Test.fail_printf (@"$result != $expected_json");
        }
    });

    Test.add_func ("/jsoner/serialize/dict/string/direct", () => {
        var expected_json = "{\"kekw\":\"yes\",\"kek\":\"no\"}";

        var obj = new Gee.HashMap<string, string> ();
        obj.set ("kekw", "yes");
        obj.set ("kek", "no");

        var result = Jsoner.serialize (obj);

        if (result != expected_json) {
            Test.fail_printf (@"$result != $expected_json");
        }
    });

    Test.add_func ("/jsoner/serialize/array/string2", () => {
        var test_object = new TestObjectArrayString ();
        test_object.value.add ("everything that lives is designed to end");
        test_object.value.add ("we are perpetually trapped in a neverending spyral of life and death");
        test_object.value.add ("is this a curse?");
        test_object.value.add ("or some kind of punishment?");
        test_object.value.add ("i often thinking about the god who blessed us with this cryptic puzzle");
        test_object.value.add ("and wonder if we'll ever have a chance to kill him");

        string expectation = "{\"value\":[\"everything that lives is designed to end\",\"we are perpetually trapped in a neverending spyral of life and death\",\"is this a curse?\",\"or some kind of punishment?\",\"i often thinking about the god who blessed us with this cryptic puzzle\",\"and wonder if we'll ever have a chance to kill him\"]}";
        string result = test_object.to_json ();

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/jsoner/serialize/array/object", () => {
        var test_object = new TestObjectArrayObject ();
        test_object.value.add (new SimpleObject ());
        test_object.value.add (new SimpleObject () { string_value = "why are we still here", int_value = 42 });
        test_object.value.add (new SimpleObject () { bool_value = false });
        test_object.value.add (new SimpleObject ());
        test_object.value.add (new SimpleObject () { string_value = "kekw" });
        test_object.value.add (new SimpleObject ());

        string expectation = "{\"value\":[{\"string-value\":null,\"int-value\":0,\"bool-value\":false},{\"string-value\":\"why are we still here\",\"int-value\":42,\"bool-value\":false},{\"string-value\":null,\"int-value\":0,\"bool-value\":false},{\"string-value\":null,\"int-value\":0,\"bool-value\":false},{\"string-value\":\"kekw\",\"int-value\":0,\"bool-value\":false},{\"string-value\":null,\"int-value\":0,\"bool-value\":false}]}";
        string result = Jsoner.serialize (test_object);

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/jsoner/serialize/array/object2", () => {
        var test_object = new TestObjectArrayObject ();
        test_object.value.add (new SimpleObject ());
        test_object.value.add (new SimpleObject () { string_value = "why are we still here", int_value = 42 });
        test_object.value.add (new SimpleObject () { bool_value = false });
        test_object.value.add (new SimpleObject ());
        test_object.value.add (new SimpleObject () { string_value = "kekw" });
        test_object.value.add (new SimpleObject ());

        string expectation = "{\"value\":[{\"string-value\":null,\"int-value\":0,\"bool-value\":false},{\"string-value\":\"why are we still here\",\"int-value\":42,\"bool-value\":false},{\"string-value\":null,\"int-value\":0,\"bool-value\":false},{\"string-value\":null,\"int-value\":0,\"bool-value\":false},{\"string-value\":\"kekw\",\"int-value\":0,\"bool-value\":false},{\"string-value\":null,\"int-value\":0,\"bool-value\":false}]}";
        string result = test_object.to_json ();

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/jsoner/serialize/array/array", () => {
        var test_object = new TestObjectArrayArray ();
        test_object.value.add (new Gee.ArrayList<SimpleObject> ());
        test_object.value.add (new Gee.ArrayList<SimpleObject> ());
        test_object.value.add (new Gee.ArrayList<SimpleObject> ());
        test_object.value[0].add (new SimpleObject ());
        test_object.value[0].add (new SimpleObject ());
        test_object.value[1].add (new SimpleObject () { string_value = "why are we still here", int_value = 42 });
        test_object.value[1].add (new SimpleObject () { bool_value = false });
        test_object.value[1].add (new SimpleObject () { string_value = "kekw" });
        test_object.value[2].add (new SimpleObject () { int_value = 56 });

        string expectation = "{\"value\":[[{\"string-value\":null,\"int-value\":0,\"bool-value\":false},{\"string-value\":null,\"int-value\":0,\"bool-value\":false}],[{\"string-value\":\"why are we still here\",\"int-value\":42,\"bool-value\":false},{\"string-value\":null,\"int-value\":0,\"bool-value\":false},{\"string-value\":\"kekw\",\"int-value\":0,\"bool-value\":false}],[{\"string-value\":null,\"int-value\":56,\"bool-value\":false}]]}";
        string result = Jsoner.serialize (test_object);

        if (result != expectation) {
            Test.fail_printf (result + " != " + expectation);
        }
    });

    Test.add_func ("/jsoner/deserialize/enum", () => {
        try {
            var jsoner = new Jsoner ("{\"value\":\"value_2\"}");
            var result = jsoner.deserialize_object<TestObjectEnum> ();

            if (result.value != TestEnum.VALUE_2) {
                Test.fail_printf (result.value.to_string () + " != " + TestEnum.VALUE_2.to_string ());
            }
        } catch (JsonError e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/jsoner/deserialize/value", () => {
        try {
            var jsoner = new Jsoner ("{\"value\":\"test\"}", {"value"});

            string result = jsoner.deserialize_value ().get_string ();

            if (result != "test") {
                Test.fail_printf (result + " != test");
            }
        } catch (JsonError e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/jsoner/deserialize/not_valid_path", () => {
        try {
            var jsoner = new Jsoner ("{\"value\":\"test\"}", {"value1"});
            jsoner.deserialize_value ();

            Test.fail_printf ("Value parsed without error");
        } catch (JsonError e) {
            Test.skip (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/jsoner/deserialize/object", () => {
        try {
            var jsoner = new Jsoner ("{\"value\":\"test\"}");
            var result = jsoner.deserialize_object<TestObjectString> ();

            if (result.value != "test") {
                Test.fail_printf (result.value + " != test");
            }
        } catch (JsonError e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/jsoner/deserialize/object2", () => {
        try {
            var result = new TestObjectString ();
            result.fill_from_json ("{\"value\":\"test\"}");

            if (result.value != "test") {
                Test.fail_printf (result.value + " != test");
            }
        } catch (JsonError e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/jsoner/deserialize/object_camel", () => {
        try {
            var jsoner = new Jsoner ("{\"stringValue\":\"test\"}", null, Case.CAMEL);
            var result = jsoner.deserialize_object<TestObjectStringCamel> ();

            if (result.string_value != "test") {
                Test.fail_printf (result.string_value + " != test");
            }
        } catch (JsonError e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/jsoner/deserialize/object_camel_", () => {
        try {
            var jsoner = new Jsoner ("{\"stringValue\":\"test\"}", null, Case.CAMEL);
            var result = jsoner.deserialize_object<TestObjectStringCamelW> ();

            if (result.string_value_ != "test") {
                Test.fail_printf (result.string_value_ + " != test");
            }
        } catch (JsonError e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/jsoner/deserialize/int_to_string", () => {
        try {
            var jsoner = new Jsoner ("{\"value\":6}");
            var result = jsoner.deserialize_object<TestObjectString> ();

            if (result.value != "6") {
                Test.fail_printf (result.value + " != \"6\"");
            }
        } catch (JsonError e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/jsoner/deserialize/int_to_double", () => {
        try {
            var json = "{\"value\":6}";

            var result = Jsoner.simple_from_json<TestObjectDouble> (json);

            if (result.value != 6.0) {
                Test.fail_printf (@"$(result.value) != 6.0");
            }
        } catch (JsonError e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/jsoner/deserialize/array/string", () => {
        try {
            var jsoner = new Jsoner ("{\"value\":[\"kekw\",\"yes\",\"no\"]}");
            var result = jsoner.deserialize_object<TestObjectArrayString> ();

            if (result.value[0] != "kekw" || result.value[1] != "yes" || result.value[2] != "no") {
                Test.fail_printf (string.joinv (", ", result.value.to_array ()) + " != kekw, yes, no");
            }
        } catch (JsonError e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/jsoner/deserialize/dict/string", () => {
        try {
            var json = "{\"value\":{\"kekw\":\"yes\",\"kek\":\"no\"}}";

            var result = Jsoner.simple_from_json<TestObjectDictString> (json);

            if (result.value["kekw"] != "yes" || result.value["kek"] != "no") {
                Test.fail_printf ("");
            }
        } catch (JsonError e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/jsoner/deserialize/array/string2", () => {
        try {
            var result = new TestObjectArrayString ();
            result.fill_from_json ("{\"value\":[\"kekw\",\"yes\",\"no\"]}");

            if (result.value[0] != "kekw" || result.value[1] != "yes" || result.value[2] != "no") {
                Test.fail_printf (string.joinv (", ", result.value.to_array ()) + " != kekw, yes, no");
            }
        } catch (JsonError e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/jsoner/deserialize/array/direct", () => {
        try {
            var jsoner = new Jsoner ("{\"value\":[\"kekw\",\"yes\",\"no\"]}", {"value"});
            var array = jsoner.deserialize_array<string> ();

            if (array[0] != "kekw" || array[1] != "yes" || array[2] != "no") {
                Test.fail_printf (string.joinv (", ", array.to_array ()) + " != kekw, yes, no");
            }
        } catch (JsonError e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/jsoner/deserialize/array/object", () => {
        try {
            var jsoner = new Jsoner ("{\"value\":[{\"string-value\":\"Baby one more time\",\"int-value\":42,\"bool-value\":true},{\"string-value\":\"I want it that way\",\"int-value\":17,\"bool-value\":false},{\"string-value\":\"Gonna make you sweat\",\"int-value\":99,\"bool-value\":true}]}");
            var result = jsoner.deserialize_object<TestObjectArrayObject> ();

            if (result.value[0].string_value != "Baby one more time" || result.value[1].int_value != 17 || result.value[2].bool_value != true) {
                Test.fail_printf (
                    result.value[0].string_value + " != Baby one more time\n" +
                    result.value[1].int_value.to_string () + " != 17\n" +
                    result.value[2].bool_value.to_string () + " != true"
                );
            }
        } catch (JsonError e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/jsoner/deserialize/array/object2", () => {
        try {
            var result = new TestObjectArrayObject ();
            result.fill_from_json ("{\"value\":[{\"string-value\":\"Baby one more time\",\"int-value\":42,\"bool-value\":true},{\"string-value\":\"I want it that way\",\"int-value\":17,\"bool-value\":false},{\"string-value\":\"Gonna make you sweat\",\"int-value\":99,\"bool-value\":true}]}");

            if (result.value[0].string_value != "Baby one more time" || result.value[1].int_value != 17 || result.value[2].bool_value != true) {
                Test.fail_printf (
                    result.value[0].string_value + " != Baby one more time\n" +
                    result.value[1].int_value.to_string () + " != 17\n" +
                    result.value[2].bool_value.to_string () + " != true"
                );
            }
        } catch (JsonError e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/jsoner/deserialize/array/array", () => {
        try {
            var jsoner = new Jsoner ("{\"value\":[[{\"value\":7}],[{\"value\":98}]]}");
            var result = jsoner.deserialize_object<TestObjectAlbum> (sub_creation);

            if (result.value[0][0].value != 7 || result.value[1][0].value != 98) {
                Test.fail_printf (
                    result.value[0][0].value.to_string () + " != 7\n" +
                    result.value[1][0].value.to_string () + " != 98\n"
                );
            }
        } catch (JsonError e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    return Test.run ();
}

void sub_creation (out Gee.Traversable collection, Type element_type) {
    if (element_type == typeof (TestObjectInt)) {
        collection = new Gee.ArrayList<TestObjectInt> ();
        return;
    }

    assert_not_reached ();
}
