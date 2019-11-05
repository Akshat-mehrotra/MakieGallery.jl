using Documenter, AbstractPlotting
using Markdown, Pkg, Random, FileIO, JSON, HTTP
using MakieGallery
import AbstractPlotting: _help, to_string, to_func, to_type
using MakieGallery: eval_examples, generate_thumbnail, master_url, print_table, download_reference
using MakieGallery: @cell, @block, @substep

function isPR()
    if haskey(ENV, "CI")
        if haskey(ENV, "TRAVIS")
            return get(ENV, "TRAVIS_PULL_REQUEST", "false") != "false"
        end
    end
    if haskey(ENV, "GITHUB_TOKEN")
        @info "Github Actions detected"
        return read(pipeline(`git branch --show-current`), String) != "master"
    end
    return false
end

isManual() = if !all(haskey.(Ref(ENV), ["GITHUB_TOKEN", "CI"]))
                return true
            end

MakieGallery.current_ref_version[] = "master"

cd(@__DIR__)
database = MakieGallery.load_database()

pathroot = normpath(@__DIR__, "..")
docspath = joinpath(pathroot, "docs")
srcpath = joinpath(docspath, "src")
buildpath = joinpath(docspath, "build")
mediapath = download_reference()


# =============================================
# automatically generate an overview of the atomic functions, using a source md file
@info("Generating functions overview")
path = joinpath(srcpath, "functions-overview.md")
srcdocpath = joinpath(srcpath, "src-functions.md")

plotting_functions = (
    AbstractPlotting.atomic_functions..., contour, arrows,
    barplot, poly, band, slider, vbox, hbox
)

open(path, "w") do io
    !ispath(srcdocpath) && error("source document doesn't exist!")
    println(io, "# Plotting functions overview")
    src = read(srcdocpath, String)
    println(io, src, "\n")
    for func in plotting_functions
        fname = to_string(func)
        println(io, "## `$fname`\n")
        println(io, "```@docs")
        println(io, "$fname")
        println(io, "```\n")
        # add previews of all tags related to function
        for example in database
            fname in example.tags || continue
            base_path = joinpath(mediapath, string(example.unique_name))
            thumb = master_url(mediapath, joinpath(base_path, "media", "thumb.jpg"))
            code = master_url(mediapath, joinpath(base_path, "index.html"))
            src_lines = example.file_range
            println(io, """[![library lines $src_lines]($thumb)]($code)""")
        end
        println(io, "\n")
    end
end


cd(docspath)

# =============================================
# automatically generate an overview of the plot attributes (keyword arguments), using a source md file
@info("Generating attributes page")
include("../src/plot_attr_desc.jl")
path = joinpath(srcpath, "plot-attributes.md")
srcdocpath = joinpath(srcpath, "src-plot-attributes.md")
open(path, "w") do io
    !ispath(srcdocpath) && error("source document doesn't exist!")
    println(io, "# Plot attributes")
    src = read(srcdocpath, String)
    println(io, src)
    print(io, "\n")
    println(io, "## List of attributes")
    print_table(io, plot_attr_desc)
end

# =============================================
# automatically generate an overview of the axis attributes, using a source md file
@info("Generating axis page")
path = joinpath(srcpath, "axis.md")
srcdocpath = joinpath(srcpath, "src-axis.md")
include("../src/Axis2D_attr_desc.jl")
include("../src/Axis3D_attr_desc.jl")

open(path, "w") do io
    !ispath(srcdocpath) && error("source document doesn't exist!")
    src = read(srcdocpath, String)
    println(io, src)
    print(io)
    # Axis2D section
    println(io, "## `Axis2D`")
    println(io, "### `Axis2D` attributes groups")
    print_table(io, Axis2D_attr_desc)
    print(io)
    for (k, v) in Axis2D_attr_groups
        println(io, "#### `:$k`\n")
        print_table(io, v)
        println(io)
    end
    # Axis3D section
    println(io, "## `Axis3D`")
    println(io, "### `Axis3D` attributes groups")
    print_table(io, Axis3D_attr_desc)
    print(io)
    for (k, v) in Axis3D_attr_groups
        println(io, "#### `:$k`\n")
        print_table(io, v)
        println(io)
    end

    # Examples on the bottom of the page
    println(io, """

    ### Examples

    @example_database("Unicode Marker")

    @example_database("Axis + Surface")

    @example_database("Axis theming")
    """)
end

# automatically generate an overview of the function signatures, using a source md file
@info("Generating signatures page")
path = joinpath(srcpath, "signatures.md")
srcdocpath = joinpath(srcpath, "src-signatures.md")
open(path, "w") do io
    !ispath(srcdocpath) && error("source document doesn't exist!")
    println(io, "# Plot function signatures")
    src = read(srcdocpath, String)
    println(io, src)
    print(io, "\n")
    println(io, "```@docs")
    println(io, "convert_arguments")
    println(io, "```\n")

    println(io, "See [Plot attributes](@ref) for the available plot attributes.")
end

# build docs with Documenter
@info("Running `makedocs` with Documenter.")


makedocs(
    modules = [AbstractPlotting],
    doctest = false, clean = true,
    format = Documenter.HTML(prettyurls = false),
    sitename = "Makie.jl",
    expandfirst = [
        "basic-tutorials.md",
        "statsmakie.md",
        # "help_functions.md",
        "animation.md",
        "interaction.md",
        "functions-overview.md",
        "scenes.md",
        "signatures.md",
        "plot-attributes.md",
        "colors.md",
        "theming.md",
        "cameras.md",
        "backends.md",
        # "extending.md",
        "axis.md",
        "recipes.md",
        "output.md"
    ],
    pages = Any[
        "Home" => "index.md",
        "Basics" => [
            "basic-tutorials.md",
            "statsmakie.md",
            # "help_functions.md",
            "animation.md",
            "interaction.md",
            "functions-overview.md",
            "animation.md",
        ],
        "Documentation" => [
            "scenes.md",
            "signatures.md",
            "plot-attributes.md",
            "colors.md",
            "theming.md",
            "cameras.md",
            "backends.md",
            # "extending.md",
            "axis.md",
            "recipes.md",
            "output.md",
            # "layout.md",
            "troubleshooting.md"
        ],
        "Developer Documentation" => [
            "why-makie.md",
            "devdocs.md",
            "gallery.md",
            "AbstractPlotting Reference" => "abstractplotting_api.md"
        ],
    ]
)

using Conda, Documenter
using Base64

# deploy the docs

ENV["DOCUMENTER_DEBUG"] = "true"
deploy_url = get(ENV, "DOCUMENTER_DEPLOY_URL", "github.com/JuliaPlots/MakieGallery.jl")


# do this only if local, otherwise let Documenter handle it
if !haskey(ENV, "CI") && !haskey(ENV, "GITHUB_TOKEN")
    # Workaround for when deploying locally and silly Windows truncating the env variable
    # on the CI these should be set!
    ENV["CI"] = "no"
    ENV["TRAVIS"] = :lolno
    ENV["TRAVIS_BRANCH"] = "master"
    ENV["TRAVIS_PULL_REQUEST"] = "false"
    ENV["TRAVIS_REPO_SLUG"] = "github.com/JuliaPlots/MakieGallery.jl"
    ENV["TRAVIS_TAG"] = ""
    ENV["TRAVIS_OS_NAME"] = ""
    ENV["TRAVIS_JULIA_VERSION"] = ""
    # ENV["PATH"] = string(ENV["PATH"], Sys.iswindows() ? ";" : ":", Conda.SCRIPTDIR)
    ENV["DOCUMENTER_KEY"] = get(ENV, "DOCUMENTER_KEY", readchomp(joinpath(homedir(), "documenter.key")))
end

############################################
# Set up for pushing preview docs from PRs #
############################################

if isPR()

    deploy_url = get(ENV, "DOCUMENTER_DEPLOY_URL", "github.com/asinghvi17/MakiePreviewDocs") 
    repo_url   = ENV["GITHUB_REPOSITORY"]
    commit_sha = ENV["GITHUB_SHA"]

    @info "Pushing preview docs."

    # Find the latest PR associated with the commit from its SHA
    r = HTTP.get(
        "https://api.github.com/repos/$repo_url/commits/$commit_sha/pulls",
        [
            "Accept" => "application/vnd.github.groot-preview+json",
            "User-Agent" => "GitHub-jl"
        ]
        )

    url = JSON.parse(String(r.body))[1]["html_url"] # get the URL of the PR
    PR = splitpath(url)[end] # get the PR number
    # Overwrite Documenter's function for generating the versions.js file
    foreach(Base.delete_method, methods(Documenter.Writers.HTMLWriter.generate_version_file))
    Documenter.Writers.HTMLWriter.generate_version_file(_, _) = nothing

    # Overwrite necessary environment variables to trick Documenter to deploy
    ENV["GITHUB_EVENT_NAME"] = "push"
    ENV["GITHUB_REF"] = "refs/heads/master"
    ENV["GITHUB_REPOSITORY"] = deploy_url

    Documenter.authentication_method(::Documenter.GitHubActions) = Documenter.SSH # make GH Actions deploy by DOCUMENTER_KEY

    deploydocs(
        devurl = "preview-PR$(PR)",
        repo = deploy_url,
    )

    # # Add a comment on the PR with a link to the preview
    # msg = "Documentation built successfully, a preview can be found here: https://makie.juliaplots.org/preview-PR$(PR)"
    # cmd = `curl -X POST`
    # push!(cmd.exec, "-H", "Authorization: token $(ENV["GITHUB_TOKEN"])")
    # push!(cmd.exec, "-H", "Content-Type: application/json")
    # push!(cmd.exec, "-d", "{\"body\":\"$(msg)\"}")
    # push!(cmd.exec, "https://api.github.com/repos/JuliaPlots/MakieGallery.jl/issues/$(PR)/comments")
    # try
    #     success(cmd)
    # catch e
    #     @warn "Curl errored when pushing comment!" exception=e
    # end
    exit(0)
end

cd(@__DIR__)

deploydocs(
    repo = deploy_url
)
