package main

import (
    "fmt"
    "log"
    "net/http"
    "os"
    "os/exec"
    "flag"
)

type Labeler struct {
    filter string
    project string
    newLabels string
}

func (labeler *Labeler) handler() http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        cmd := exec.CommandContext(r.Context(), "/bin/bash", "update_labels.sh", "--filter", labeler.filter, "--project", labeler.project, "--new-labels", labeler.newLabels)
        fmt.Println("Executing command:", cmd.String())
        cmd.Stderr = os.Stderr
        out, err := cmd.Output()
        if err != nil {
            w.WriteHeader(500)
        }
        w.Write(out)
    }
}

func main() {
    filterArg := flag.String("filter", "", "Filter the resources to apply labels to")
    projectArg := flag.String("project", "", "Project for filtering some resources")
    newLabelsArg := flag.String("new-labels", "", "New labels to apply to the filtered resources")
    flag.Parse()

    filter := *filterArg
    newLabels := *newLabelsArg
    project := *projectArg
    if filter == "" {
        filter = os.Getenv("FILTER")
    }
    if project == "" {
        project = os.Getenv("PROJECT")
    }
    if newLabels == "" {
        newLabels = os.Getenv("NEW_LABELS")
    }
    if filter == "" || newLabels == "" || project == "" {
        fmt.Println("filter, project and new-labels are required. Either use --filter, --project and --new-labels or set FILTER, PROJECT and NEW_LABELS environment variables.")
        os.Exit(1)
    }
    labeler := &Labeler{
        filter: filter,
        project: project,
        newLabels: newLabels,
    }

    http.HandleFunc("/", labeler.handler())

    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    log.Fatal(http.ListenAndServe(fmt.Sprintf(":%s", port), nil))
}