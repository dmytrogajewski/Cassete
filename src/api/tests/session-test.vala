// ind-check=skip-file
// vala-lint=skip-file

using ApiBase;

class UserAgentInfo : DataObject {
    public string user_agent { get; set; }
}

class CookiesInfo : DataObject {
    public Gee.HashMap<string, string> cookies { get; set; default = new Gee.HashMap<string, string> (); }
}

const string EXPECTED_JSON = """{
  "slideshow": {
    "author": "Yours Truly", 
    "date": "date of publication", 
    "slides": [
      {
        "title": "Wake up to WonderWidgets!", 
        "type": "all"
      }, 
      {
        "items": [
          "Why <em>WonderWidgets</em> are great", 
          "Who <em>buys</em> WonderWidgets"
        ], 
        "title": "Overview", 
        "type": "all"
      }
    ], 
    "title": "Sample Slide Show"
  }
}
""";

const string EXPECTED_ROBOTS = """User-agent: *
Disallow: /deny""";

const string EXPECTED_POST_START = """{
  "args": {}, 
  "data": "", 
  "files": {}, 
  "form": {
    "comments": "FAST", 
    "custemail": "rirusha@altlinux.org", 
    "custname": "Rirusha", 
    "custtel": "666666", 
    "delivery": "", 
    "size": "large"
""";

const string USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 YaBrowser/24.10.0.0 Safari/537.36";

public int main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/soup-wrapper/get", () => {
        try {
            var request = new Request.GET ("https://httpbin.org/get");
            request.simple_exec ();

        } catch (Error e) {
            Test.fail_printf ("Error: \n%s", e.message);
        }
    });

    Test.add_func ("/soup-wrapper/get/json", () => {
        try {
            var soup_wrapper = new Session (USER_AGENT);
            var request = new Request.GET ("https://httpbin.org/json");
            var response = (string) (soup_wrapper.exec (request).get_data ());

            if (response.strip () != EXPECTED_JSON.strip ()) {
                Test.fail_printf ("Wrong result: \n%s", response);
            }
        } catch (Error e) {
            Test.fail_printf ("Error: \n%s", e.message);
        }
    });

    Test.add_func ("/soup-wrapper/delete", () => {
        try {
            var request = new Request.DELETE ("https://httpbin.org/delete");
            request.simple_exec ();

        } catch (Error e) {
            Test.fail_printf ("Error: \n%s", e.message);
        }
    });

    Test.add_func ("/soup-wrapper/patch", () => {
        try {
            var request = new Request.PATCH ("https://httpbin.org/patch");
            request.simple_exec ();

        } catch (Error e) {
            Test.fail_printf ("Error: \n%s", e.message);
        }
    });

    Test.add_func ("/soup-wrapper/post", () => {
        try {
            var request = new Request.POST ("https://httpbin.org/post");
            request.simple_exec ();

        } catch (Error e) {
            Test.fail_printf ("Error: \n%s", e.message);
        }
    });

    Test.add_func ("/soup-wrapper/put", () => {
        try {
            var request = new Request.PUT ("https://httpbin.org/put");
            request.simple_exec ();

        } catch (Error e) {
            Test.fail_printf ("Error: \n%s", e.message);
        }
    });

    Test.add_func ("/soup-wrapper/error-status", () => {
        try {
            var request = new Request.GET ("https://httpbin.org/status/500");
            request.simple_exec ();

        } catch (BadStatusCodeError e) {
            if (e is BadStatusCodeError.INTERNAL_SERVER_ERROR) {
                return;
            }
            Test.fail_printf ("Error: \n%s", e.message);
        } catch (Error e) {
            Test.fail_printf ("Error: \n%s", e.message);
        }
    });

    Test.add_func ("/soup-wrapper/user-agent", () => {
        try {
            var soup_wrapper = new Session (USER_AGENT);
            var request = new Request.GET ("https://httpbin.org/user-agent");
            var respone = (string) (soup_wrapper.exec (request).get_data ());

            var obj = Jsoner.simple_from_json<UserAgentInfo> (respone);

            if (obj.user_agent != USER_AGENT) {
                Test.fail ();
            }

        } catch (Error e) {
            Test.fail_printf ("Error: \n%s", e.message);
        }
    });

    Test.add_func ("/soup-wrapper/post/data/dict", () => {
        try {
            var request = new Request.POST ("https://httpbin.org/post");

            PostContent post_content = { X_WWW_FORM_URLENCODED };

            var dict = new Gee.HashMap<string, string> ();
            dict["custname"] = "Rirusha";
            dict["custtel"] = "666666";
            dict["custemail"] = "rirusha@altlinux.org";
            dict["size"] = "large";
            dict["delivery"] = "";
            dict["comments"] = "FAST";

            post_content.set_dict (dict);
            request.add_post_content (post_content);
            var response = (string) (request.simple_exec ().get_data ());

            if (!(response.strip ().has_prefix (EXPECTED_POST_START))) {
                Test.fail ();
            }

        } catch (Error e) {
            Test.fail_printf ("Error: \n%s", e.message);
        }
    });

    Test.add_func ("/soup-wrapper/post/data/datalist", () => {
        try {
            var request = new Request.POST ("https://httpbin.org/post");

            PostContent post_content = { X_WWW_FORM_URLENCODED };

            var datalist = Datalist<string> ();
            datalist.set_data ("custname", "Rirusha");
            datalist.set_data ("custtel", "666666");
            datalist.set_data ("custemail", "rirusha@altlinux.org");
            datalist.set_data ("size", "large");
            datalist.set_data ("delivery", "");
            datalist.set_data ("comments", "FAST");

            post_content.set_datalist (datalist);
            request.add_post_content (post_content);
            var response = (string) (request.simple_exec ().get_data ());

            if (!(response.strip ().has_prefix (EXPECTED_POST_START))) {
                Test.fail ();
            }

        } catch (Error e) {
            Test.fail_printf ("Error: \n%s", e.message);
        }
    });

    Test.add_func ("/soup-wrapper/header", () => {
        try {
            var request = new Request.GET ("https://httpbin.org/robots.txt");
            request.add_header ("accept", "text/plain");

            var response = (string) (request.simple_exec ().get_data ());

            if (!(response.strip () == EXPECTED_ROBOTS)) {
                Test.fail ();
            }

        } catch (Error e) {
            Test.fail_printf ("Error: \n%s", e.message);
        }
    });

    Test.add_func ("/soup-wrapper/headers-preset", () => {
        try {
            var session = new Session ();
            session.add_headers_preset ("test", {
                { "accept", "text/plain" }
            });

            var request = new Request.GET ("https://httpbin.org/robots.txt");
            request.add_header ("accept", "text/plain");

            var response = (string) (session.exec (request).get_data ());

            if (!(response.strip () == EXPECTED_ROBOTS)) {
                Test.fail ();
            }

        } catch (Error e) {
            Test.fail_printf ("Error: \n%s", e.message);
        }
    });

    return Test.run ();
}
