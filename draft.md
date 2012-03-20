I started playing with Go language around 9 months ago. I was
very curious and excited about it due its nice concurrency model.
On a daily basis I develop backends of web applications, but I 
have very strong system programming background, thus I really liked
to get known more about that "new system programming language".

But after a while I discovered that Go is not system programming
language only. The language itself is very flexible and allows
me to do lot of nice and funny stuff.

I was also very surprised that Go is great for powering up Web
applications, and that's the topic of my today's talk.

# Go for Web-services

I will show you a little bit information about writing Web-services
in Go, but also about full stack Web applications. I am sure you gonna
like it.

## Why Go?

First of all, why we should even consider writing Web stuff in Go?
Or maybe I will ask different question... What are your common
problems in your web applications?

* Performance
* Memory consumption
* Undetected bugs
* Scalability
* ...

So... you have the answer now. Go applications performs splendidly,
have very small memory footprint, they have less unexpected bugs
thanks to static typing and they scale.

## Hello world!

    package main
    
    import (
        "fmt"
        "net/http"
    )
    
    func handler(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "Hello World!\n")
    }
    
    func main() {
        http.HandleFunc("/", handler)
        http.ListenAndServe(":8080", nil)
    }
    
Here we go, this is very simple hello world application. The net/http
package implements most of the features we gonna use for serving
web apps. It implements very efficient and flexible web server. 
Besides some very high scale cases it works very good and is very
stable.

To serve something specific we have to declare our handler. In this
case handler is simple function which takes two parameters. An response
writer - magic object which gathers information about our response,
and request object, containing all the information about performed
request.

The http.HandleFunc binds defined handler to specified path. You
can imagine that as very simple and privimite routing mechanism...

## Custom handlers...

Ok, let's move little bit forward now. First examples used function
as a handler. But handler itself is an interface. The http.Handler
interface is defined like this:

    type Handler interface {
        ServeHTTP(ResponseWriter, *Request)
    }
    
Does everyone know how interfaces in Go looks like?

Nope? Ok, so interface is typical duck typing mechanism. Take a look
at this interface, http.Handler. If any of defined structure responds
to ServeHTTP function with the same parameters, then can be used
wherever the http.Handler is required. Here's an example:

    type HelloHandler struct {}
    
    func (h *HelloHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "Hello World!\n")
    }

Yeah, everyone got it? 
So now you may ask why do we need some custom handler, right? Well,
it's the same idea as with Rack middlewares. Custom handlers can be
used to build full stack applications, with some states, internal
variables etc.

Using that kind of handlers we can build some more sophisticated
router for example. I will tell you about it little bit later.
Now let's go back to our example. I will give you some briefing
with the most common stuff, and then we will go into some real
life examples.

## Content-type & headers

So, one of the most important features, specifying Content-type
and dealing with other HTTP headers. It's very simple stuff to do,
take a look:

    import "encoding/json"

    func (h *HelloHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "application/json")
        enc := json.NewEncoder(w)
        enc.Encode(map[string]string{"hello": "World"})
    }

Response writer provides Header() function, which is a cool wrapper
for the headers map. We can use it to set our content type to
JSON.

Very cool thing about go is that it stick very close to all the
interfaces defined around. For example, http.ResponseWriter is
an io.Writer as well, because implements Write func the way
io.Writer requires it. Thanks to this, we can use http.ResponseWriter
for example as a json.Encoder destination. So as you can see
we have json.Encoder bound to response writer variable, so
further encoded data will be written there. Cool, isn't it?

## Response status, form params...

Next super important thing i suppose is to be able to set response
status. Also, it would be cool to access form/url params, don't you
think?

    func (h *HelloHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
        r.ParseForm()
        w.Header().Set("Content-Type", "application/json")
        enc := json.NewEncoder(w)
        who := r.FormValue("name")
   
        if who == "Kamil" {
            w.WriteHeader(http.StatusForbidden)
            enc.Encode(map[string]string{"gtfo": who})
        } else {
            enc.Encode(map[string]string{"hello": who})
        }
    }

So, http.Request provides ParseForm() function, we have to call it 
manually in order to access form or get parameters. To get its values
we gonna use r.FormValue() function.

Now we can figure out who want's to say hello to us. If it is my
friend Kamil sitting out there, of course we will not let him in...
We gonna show the forbidden status to him and make him get the
fuck out :). 

What's preety handy, http package defines constants for all the
status codes specified in HTTP RFC document. It's very good
when we don't remember the status code itself, but we do have
its name on mind. So yeah, we can use StautsNotFound, 
StatusInternalServerError and so on.

To set that status, we gonna use response writer's function
with that tricky name, WriteHeader. This functions sets response
status.

## Request information

Now when we know how to get some basic form parameters from the
request, we can go little bit deeper and get some more information. 
For example, we may want to display our greeting only when
request method is GET. 

Let's go back then to our simplified example:

    func (h *HelloHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
        if r.Method == "GET" {
            w.Header().Set("Content-Type", "application/json")
            enc := json.NewEncoder(w)
            enc.Encode(map[string]string{"hello": "World"})
        } else {
            w.WriteHeader(http.StatusMethodNotAllowed)
        }
    }

Super simple, http.Request provides bunch of useful properties
and functions to access its information.

    import "regexp"

    userAgentValidation := regexp.MustCompile("MSIE")

    func (h *HelloHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "application/json")
        enc := json.NewEncoder(w)
        if userAgentValidation.MatchString(r.UserAgent()) {
            w.WriteHeader(http.StatusForbidden)
            enc.Encode(map[string]string{"fuck_you": "IE"})
        } else {
            enc.Encode(map[string]string{"hello": "World"})
        }
    }

Yeah, we can forbid access to IE users, they don't have nice JSON 
formatting implemented :).

http.Request provides lot more features. You can access cookies, 
forms, headers, URL, body, and so on. I will not show you all the 
examples, check out the documentation, everything's pretty nice 
described there. 

## Redirecting

Now let's say that we want to troll IE users even more... Instead
of not letting them pass through, lets redirect them!

    import "regexp"

    userAgentValidation := regexp.MustCompile("MSIE")

    func (h *HelloHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
        if userAgentValidation.MatchString(r.UserAgent()) {
            http.Redirect(w, r, "http://www.mozilla.org/en-US/firefox/new/", 
                http.StatusTemporaryRedirect)
        } else {
            w.Header().Set("Content-Type", "application/json")
            enc := json.NewEncoder(w)
            enc.Encode(map[string]string{"hello": "World"})
        }
    }
    
Here we go, Firefox motherfucker, do you have it?

## Serving files

But... that's not the limit of trolling yet! We can serve copy of
firefox binaries, and make them download it automatically when
they want to see our site!

    import "regexp"

    userAgentValidation := regexp.MustCompile("MSIE")

    func (h *HelloHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
        if userAgentValidation.MatchString(r.UserAgent()) {
            http.Redirect(w, r, "/files/firefox.zip", http.StatusTemporaryRedirect)
        } else {
            w.Header().Set("Content-Type", "application/json")
            enc := json.NewEncoder(w)
            enc.Encode(map[string]string{"hello": "World"})
        }
    }

Here we go our redirect, and to serve the files we have to bind
other handler to our server, take a look:

    func main() {
        http.HandleFunc("/", &HelloHandler{})
        http.Handle("/files", http.FileServer(http.Dir("files")))
        http.ListenAndServe(":8080", nil)    
    }    

Eat it bastards! There's also second nice way to serve files. Let
say that you don't want to serve whole the directory, only some 
selected files. It's pretty easy to do.

    import "regexp"

    userAgentValidation := regexp.MustCompile("MSIE")

    func (h *HelloHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
        if userAgentValidation.MatchString(r.UserAgent()) {
            http.ServeFile(w, r, "./files/firefox.zip")    
        } else {
            w.Header().Set("Content-Type", "application/json")
            enc := json.NewEncoder(w)
            enc.Encode(map[string]string{"hello": "World"})
        }
    }

Yeah, so now we can serve the file directly to the slacker on IE
when he enters the page.

## Web APIs

Now you know how to build very simple web services in Go. To be
hones personally I think that this knowledge is totally enough
to work with. Working with the standard handlers forces you
to build micro applications doing one thing right. They are easy
to deploy, scale and measure.

But some people may want to build bigger applications, bigger
APIs, yeah I understand that, I'd rather encourage you to not
do it, but since this is 30 minutes presentation and I have to
fill it in with some content, let's talk about more sophisticated
APIs.

We have few options here. We can build our own Router, which is
pretty easy, or we can use some already written package to deal
with it. 

## pat.go

We have for example pat.go. It's a Sinatra-like router, written by
Blake Mizerany, original creator of Sinatra. Blake said on
#go-nuts mailing list that he approves it. I approve it as well,
it's very small and pretty cool package. What's the best about
it, it does not play around with some custom handler functions,
only allows us to use the default handlers, take a look.

    import (
        "github.com/bmizerany/pat"
        "net/http"
        "fmt"
    )
    
    func hello(w http.ResponseWriter, r *http.Request) {
        name := r.URL.Query().Get(":name")
        fmt.Fprintf(w, "Hello, %s!", name)
    }
    
    func main() {
        mux := pat.New()
        mux.Get("/hello/:name", http.HandleFunc(helloHandler))
        http.ListenAndServe(":8080", mux)
    }

So pat deals with routing, and then passes all the values to
get params. We can access them from the request URL object,
or like I was showing before via FormValue() function. I just wanted
to show you some alternative way here. You probably noticed that
keys are prefixed with colon. It's very important, you have to
remember that when you're using pat. And that's pretty much all
the features of this multiplexer. Do you need something more?
Do you? In case you do, there's something even more sophisticated.

## Gorilla

We have gorilla framework out there. This is set of widely used
web features like routing, sessions, secured cookies, request
contexts, RPCs, and so on. Here's trivial example how to use
sessions with Gorilla:

    import (
        "net/http"
        "code.google.com/p/gorilla/sessions"
    )

    var store = sessions.NewCookieStore([]byte("something-very-secret"))

    func SessionHandler(w http.ResponseWriter, r *http.Request) {
        session, _ := store.Get(r, "session-name")
        
        // Set some session values.
        session.Values["foo"] = "bar"
        session.Values[42] = 43
        
        // Save it.
        session.Save(r, w)
    }

For you who are familiar with Rails and can't live without flash
messages there's some nice feature you gonna love. Gorilla session
supports flash messages as well, take a look:

    func MyHandler(w http.ResponseWriter, r *http.Request) {
        session, _ := store.Get(r, "session-name")

        if flashes := session.Flashes(); len(flashes) > 0 {
            fmt.Fprint(w, "%v", flashes)
        } else {
            session.AddFlash("Hello, flash messages world!")
            fmt.Fprint(w, "No flashes found.")
        }

        session.Save(r, w)
    }
    
Yeah, you like it?

## Templates

Ok, so now guys you probably want to render something, right?
Yeah, go standard library contains "html/template" package with some
super simple and efficient templating. Here's some trivial example
of usage:

    import "html/template"
    ...
    t, err := template.New("foo").Parse(
        `{{define "T"}}Hello, {{.}}!{{end}}`)
    err = t.ExecuteTemplate(out, "T", 
         "<script>alert('you have been pwned')</script>")

But to be hones, I have no clue how it works because I was never
using it. I strongly believe that there's no sense in building
full stack applications in Go the way we used to do this in Ruby,
simply because of it's static typing. I think that instead we
can build APIs in Go and consume them from JavaScript, for example
using Backbone. This way we can use power of both languages for 
their most comfortable use cases. Also, we can offload our application
a little bit to the client side.
