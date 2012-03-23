!SLIDE
# Hello!

!SLIDE
# Krzysztof Kowalik

!SLIDE
# Call me Chris...

!SLIDE
# @nu7hatch

!SLIDE
# www.nu7hat.ch

!SLIDE small
# www.areyoufuckingcoding.me

!SLIDE
# Poland...

!SLIDE
# ...Uruguay

!SLIDE
# Cows

!SLIDE
# Gauchos

!SLIDE
# Beef

!SLIDE
# Tango

!SLIDE
# Football

!SLIDE
# Mate

!SLIDE
# Cubox!

!SLIDE
# www.cuboxlabs.com

!SLIDE
# Presents!

!SLIDE 
# Go for web-services

!SLIDE bullets incremental
# Why Go?

* Performance
* Memory consumption
* Undetected bugs
* Scalability

!SLIDE
# Hello World!

!SLIDE

    @@@ cpp
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

!SLIDE
# Custom handlers

!SLIDE

    @@@ cpp
    type Handler interface {
        ServeHTTP(ResponseWriter, *Request)
    }

!SLIDE

    @@@ cpp
    type HelloHandler struct {}
    
    func (h *HelloHandler) ServeHTTP(w http.ResponseWriter, 
        r *http.Request) {
        fmt.Fprintf(w, "Hello World!\n")
    }

!SLIDE
# HTTP headers

!SLIDE

    @@@ cpp
    import "encoding/json"

    func (h *HelloHandler) ServeHTTP(w http.ResponseWriter, 
        r *http.Request) {
        w.Header().Set("Content-Type", "application/json")
        enc := json.NewEncoder(w)
        enc.Encode(map[string]string{"hello": "World"})
    }

!SLIDE
# Response statuses, form params...

!SLIDE

    @@@ cpp
    func (h *HelloHandler) ServeHTTP(w http.ResponseWriter, 
        r *http.Request) {
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
    
!SLIDE
# Request information

!SLIDE

    @@@ cpp
    func (h *HelloHandler) ServeHTTP(w http.ResponseWriter, 
        r *http.Request) {
        if r.Method == "GET" {
            w.Header().Set("Content-Type", "application/json")
            enc := json.NewEncoder(w)
            enc.Encode(map[string]string{"hello": "World"})
        } else {
            w.WriteHeader(http.StatusMethodNotAllowed)
        }
    }

!SLIDE
# Redirecting

!SLIDE

    @@@ cpp
    import "regexp"

    userAgentValidation := regexp.MustCompile("MSIE")

    func (h *HelloHandler) ServeHTTP(w http.ResponseWriter, 
        r *http.Request) {
        if userAgentValidation.MatchString(r.UserAgent()) {
            http.Redirect(w, r, 
                "http://www.mozilla.org/en-US/firefox/new/", 
                http.StatusTemporaryRedirect)
        } else {
            w.Header().Set("Content-Type", "application/json")
            enc := json.NewEncoder(w)
            enc.Encode(map[string]string{"hello": "World"})
        }
    }
    
!SLIDE
# Serving files

!SLIDE

    @@@ cpp
    import "regexp"

    userAgentValidation := regexp.MustCompile("MSIE")

    func (h *HelloHandler) ServeHTTP(w http.ResponseWriter, 
        r *http.Request) {
        if userAgentValidation.MatchString(r.UserAgent()) {
            http.Redirect(w, r, "/files/firefox.zip", 
                http.StatusTemporaryRedirect)
        } else {
            w.Header().Set("Content-Type", "application/json")
            enc := json.NewEncoder(w)
            enc.Encode(map[string]string{"hello": "World"})
        }
    }

!SLIDE

    @@@ cpp
    func main() {
        http.HandleFunc("/", &HelloHandler{})
        http.Handle("/files", 
            http.FileServer(http.Dir("files")))
        http.ListenAndServe(":8080", nil)    
    }    

!SLIDE

    @@@ cpp
    import "regexp"

    userAgentValidation := regexp.MustCompile("MSIE")

    func (h *HelloHandler) ServeHTTP(w http.ResponseWriter, 
        r *http.Request) {
        if userAgentValidation.MatchString(r.UserAgent()) {
            http.ServeFile(w, r, "./files/firefox.zip")    
        } else {
            w.Header().Set("Content-Type", "application/json")
            enc := json.NewEncoder(w)
            enc.Encode(map[string]string{"hello": "World"})
        }
    }

!SLIDE
# Bigger APIs

!SLIDE
# pat.go

!SLIDE

    @@@ cpp
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

!SLIDE
# Gorilla

!SLIDE
# Sessions

!SLIDE

    @@@ cpp
    import (
        "net/http"
        "code.google.com/p/gorilla/sessions"
    )

    var store = sessions.NewCookieStore(
        []byte("something-very-secret"))

    func SessionHandler(w http.ResponseWriter, 
        r *http.Request) {
        session, _ := store.Get(r, "session-name")
        
        // Set some session values.
        session.Values["foo"] = "bar"
        session.Values[42] = 43
        
        // Save it.
        session.Save(r, w)
    }

!SLIDE
# Full stack apps?

!SLIDE
# Flash messages

!SLIDE

    @@@ cpp
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

!SLIDE
# Templates

!SLIDE

    @@@ cpp
    import "html/template"
    ...
    t, err := template.New("foo").Parse(
        `{{define "T"}}Hello, {{.}}!{{end}}`)
    err = t.ExecuteTemplate(out, "T", 
         "<script>alert('you have been pwned')</script>")

!SLIDE
# Go in real life?

!SLIDE
# nu7hatch/golaroid

!SLIDE
# webrocket/webrocket

!SLIDE
# Questions

!SLIDE
# Thanks!

!SLIDE
# Presents, yay!
