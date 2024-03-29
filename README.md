# McGill Graduate Association of Physics Students website

This repository hosts the source material and code for the newest version of the MGAPS website, [visible here](https://mgaps.physics.mcgill.ca).

## Table of contents

-   [The MGAPS website compiler](#the-mgaps-website-compiler)
-   [The website source](#the-website-source)
    -   [Updating the front page](#updating-the-front-page)
    -   [Updating static content](#updating-static-content)
    -   [Updating profiles](#updating-profiles)
    -   [Updating quick links](#updating-quick-links)
    -   [Updating files](#updating-files)
    -   [Updating images](#updating-images)
-   [What cannot be changed](#what-cannot-be-changed)
-   [Local Usage](#local-usage)
    -   [Building the compiler locally](#building-the-compiler-locally)
    -   [Available commands](#available-commands)
    -   [Building the website](#building-the-website)
    -   [Testing the website](#testing-the-website)
-   [Deployment](#deployment)
    -   [Manual deployment](#manual-deployment)

## The MGAPS website compiler

The MGAPS website is built from source files by a compiler, `mgaps-website`.

This compiler takes source material and turns it into a static website, automating as many tasks as possible for easiest maintainability. The resulting website works on both desktop _and_ mobile.

If you have any questions, feel free to [raise an issue](https://github.com/MGAPS/mgaps-website/issues/new).

## The website source

The `mgaps-website` compiler expects certain things from your website source. You need at least:

* A `static/` directory, containing static website content;
    * A `static/quick-links/` directory containing quick links information;
* A `template/` directory containing HTML templates;
* An `image/` directory containing images;
    * An `image/profile/` directory containing profile pictures;
* `people/council/` and `people/officers/` directories containing profiles (more on this later);
* `js/` and `css/` directory containing the appropriate files;

### Updating the front page

While most content handled by `mgaps-website` is in the Markdown format, the front page `index.html` is a mix of HTML and Markdown to allow for easier layout control.

### Updating static content

This is where you will edit the pages within the website. The pages can be found under the `static/` directory.
Static content is written in [Markdown](https://daringfireball.net/projects/markdown/syntax) format. Using this format, you have access to many features, including links, images, bullet lists, tables, code blocks, quotes, and many more.

To update a static page, simply edit the source Markdown file. `mgaps-website` will compile Markdown source to HTML during compilation.

Static pages have metadata at the top. At this time, the following metadata is available:

* title (required): title of the page. This title will appear in the top banner.
* withtoc (optional): if `withtoc: yes`, a table of content will be automatically inserted at the top of the page.
* tocdepth (optional): Table of content depth. For example, if `tocdepth: 2`, level 1 and level 2 headings are taken into account in the generation of the table of content.
* contact (optional): the `contact` field specifies what MGAPS VP or officer is responsible for this page. This field must match at least one of the VPs or Officers. Contact information will be automatically added to the page.

Here's an example:

```markdown
---
title: Test Page
contact: President
withtoc: yes
tocdepth: 4
---

# Level 1 heading

```

### Updating profiles

`mgaps-website` will automatically create a webpage called `people.html` based on the content of the `people/council/` and `people/officers/` directories. 

The files in these directories should all be Markdown files with the following metadata:

* name (required): Person name;
* email (required): email address;
* position (required): Position within MGAPS. If a person holds more than one position, many profiles will have to be created.
* picture (optional): path to a profile picture, usually of the form `images/profiles/something.jpg`.

The body of the file is anything that will appear as profile description. Here's an example of a profile:

```markdown
---
name: My Name
email: my.name@domain.com
position: VP Academic
picture: images/profiles/ny-name.jpg
---

As the VP Academic, it is my job to contribute to a positive academic 
experience for MGAPS members.
```

The name of the files is completely irrelevant. Profiles can be added by adding a new markdown file. The distinction between `people/council/` and `people/officers/` is only so that the `people.html` is easier to navigate.

Profiles __NOT IN__ `people/council/` or `people/officers/` will be ignored.

#### Linking to a profile

An anchor is automatically created for every profile. For example, a profile with `position: President` can be reached at the location `people.html#President`, while a profile with `position: VP Academic` can be reached at location `people.html#VP Academic`.

In case where there are two positions with the same name (e.g. two PGSS representatives), the anchor will be placed on the profile that comes alphabetically first.

### Updating quick links

The front page `index.html` has five quick links. These links are specified in Markdown files, in the `static/quick-links/` directory, with the following metadata:

* title (required): Title of the quick link
* link (required): Link to the resource

An example of a quick-link file is presented below:

```markdown
---
name: McGill Society of Physics Students
link: http://msps.sus.mcgill.ca/
---

McGill's offical organisation representing the undergraduates in physics
```

The name of the files in `static/quick-links/` directory are not important. However, strange things might happen if the number of quick links changes to anything else than __five__.

### Updating files

Files can be hosted on this website, as long as they are stored in the `files/` folder. Any file in this folder will be included in the website as-is. These files can be linked to from any Markdown file using the link syntax, for example:

```markdown
...
The GA minutes are available [here](/files/ga_minutes_2018.pdf)
...
```

### Updating images

Images must be stored in the `images/` directory. Subdirectories, like `images/profiles/`, are also supported. There are two cases:

* JPEG images (`*.jpg` and `*.jpeg`) are compressed automatically;
* Non-JPEG images are copied as-is.

I urge you to use JPEGs as much as possible, especially for pictures/photos, as the compression pipeline in `mgaps-website` is very space-efficient.

## What cannot be changed

For ease of use, the `mgaps-website` compiler forces certain things to stay the same. These are:

* The overall page template cannot be changed. This includes navigation bar, top banners, and page footer. `mgaps-website` will generated the layout `templates/default.html` automatically, and all changes to it will be overwritten;
* The website schema, or website map. Navigation links (visible in the navigation bar) are generated by the compiler. New webpages can always be added (in the `static/` directory) but these webpages cannot be linked from the navigation bar unless the compiler source code is changed;
* The order of profiles in `people.html`. For technical reasons, the only guaranteed order is that the President comes first.


## Local Usage

### Building the compiler locally

Building the `mgaps-website` compiler requires the [Haskell `stack`](https://docs.haskellstack.org/en/stable/README/) tool, which will install all dependencies. To build the compiler, run `stack install` from the same directory where `mgaps-website.cabal` and `stack.yaml` are located.

### Available commands

The `mgaps-website` compiler is a command-line program with a few options. An overview of the available commands is available as follows:

```
> mgaps-website --help
Usage: mgaps-website.exe [-v|--verbose] COMMAND
  mgaps-website.exe - Static site compiler created with Hakyll

Available options:
  -h,--help                Show this help text
  -v,--verbose             Run in verbose mode

Available commands:
  build                    Generate the site
  check                    Validate the site output
  clean                    Clean up and remove cache
  deploy                   Upload/deploy your site
  rebuild                  Clean and build again
  server                   Start a preview server
  watch                    Autocompile on changes and start a preview server.
```

### Building the website

 The most useful command is `build`, used to compile the website source into a built website:

```
> mgaps-website build
Initialising...
  Creating store...
  Creating provider...
  Running rules...
Checking for out-of-date items
Compiling
  updated templates/default.html
  (... omitted ...)
  updated static/workspace/fridges.md
  updated sitemap.xml
  updated static/index.html
Success
```

This command will update the last built website version into a folder called `/_rendered/`. The compiler will only look at items that have changed; to trigger a rebuild from scratch, you can use `mgaps-website rebuild`.

### Testing the website

Once the website has been built using `mgaps-website build` or `mgaps-website rebuild`, the rendered website can be checked for common mistakes (such as nonexistent links) using the `check` command:

```
> mgaps-website check
Checking file _rendered/workspace.html
(... omitted ...)
Checking file _rendered/finances.html
Checking file _rendered/events.html
```

The rendered website should be checked before publishing!

## Deployment

__Deployment of the website is automated.__

Simply commit the changes to the website source (in `static/`, `people/`, etc.). Once changes on the master repository are detected, the following will happen: 

1. A build server (provided by GitHub) will clone the content of the website;
2. the Haskell toolchain will be installed;
3. the compiler `mgaps-website` will be built;
4. `mgaps-website` will be used to render the website in `_rendered/`
6. the changes in `_rendered/` will be committed to appropriate branch.
