# McGill Graduate Association of Physics Students website
This repository hosts the source material and code for the newest version of
the MGAPS website, [visible here](https://mgaps.physics.mcgill.ca).

## Table of contents
-   [The MGAPS website compiler](#the-mgaps-website-compiler)
-   [The website source](#the-website-source)
    -   [Updating the front page](#updating-the-front-page)
    -   [Updating static content](#updating-static-content)
    -   [Updating profiles](#updating-profiles)
    -   [Updating quick links](#updating-quick-links)
    -   [Updating files](#updating-files)
    -   [Updating images](#updating-images)
-   [Local Usage](#local-usage)
    -   [Available commands](#available-commands)
    -   [Building the website](#building-the-website)
    -   [Testing the website](#testing-the-website)
-   [Deployment](#deployment)
    -   [Manual deployment](#manual-deployment)

## The MGAPS website compiler
The MGAPS website uses the Hugo framework (written in the Go programming
language) to build a static website from a combination of markdown, HTML, CSS
and javascript files. The choice of this framework is for ease of
maintainability, as most of the necessary changes take place within markdown
files (e.g. changing profiles), while still allowing for layout changes and the
like. The resulting website works on both desktop _and_ mobile. If you have any
questions, feel free to [raise an issue](https://github.com/MGAPS/mgaps-website/issues/new).

## The website source
The `mgaps-website` compiler expects certain things from your website source.
You need at least:
- A `static/` directory, containing static website content;
    - This includes css, javascript and mutimedia like images, PDF files, etc.
- A `template/` directory containing HTML templates.
- `people/council/` and `people/officers/` directories containing profiles
  (more on this later).
- `js/` and `css/` directory containing the appropriate files.

### Updating the front page
While most content handled by `mgaps-website` is in the Markdown format, the
front page `_index.html` (found in the `/content` directory), is a mix of HTML
and Markdown to allow for easier layout control.

### Updating content
This is where you will edit the pages within the website. The pages can also be
found under the `content/` directory. Content is written in
[Markdown](https://daringfireball.net/projects/markdown/syntax) format. Using
this format, you have access to many features, including links, images, bullet
lists, tables, code blocks, quotes, and many more. To update a page, simply
edit the source Markdown file. `mgaps-website` will compile Markdown source to
HTML during compilation. Pages have metadata at the top. At this time,
the following metadata is available:
- title (required): title of the page. This title will appear in the top
  banner.
- withtoc (optional): if `withtoc: yes`, a table of content will be
  automatically inserted at the top of the page.
- tocdepth (optional): Table of content depth. For example, if `tocdepth: 2`,
  level 1 and level 2 headings are taken into account in the generation of the
  table of content.
- contact (optional): the `contact` field specifies what MGAPS VP or officer is
  responsible for this page. This field must match at least one of the VPs or
  Officers. Contact information will be automatically added to the page. Here's
  an example:

```
---
title: Test Page
contact: President
toc: yes
tocdepth: 4
---
```


### Updating profiles
Profiles for council memebers and officers can be found in  `/content/people/`.
Here, a directory for `/council` and `/officers` can be found. Within these
directories can be found Markdown files with the following metadata:
* name (required): Person name;
* email (required): email address;
* position (required): Position within MGAPS. If a person holds more than one
  position, many profiles will have to be created.
* picture (optional): path to a profile picture, usually of the form
  `images/profiles/something.jpg`.
The body of the file is anything that will appear as profile description.
Here's an example of a profile:
```
---
name: My Name
email: my.name@domain.com
position: VP Academic
picture: images/profiles/ny-name.jpg
---
As the VP Academic, it is my job to contribute to a positive academic 
experience for MGAPS members.
```
The name of the files is completely irrelevant. Profiles can be added by adding
a new markdown file. 

#### Linking to a profile
An anchor is automatically created for every profile. For example, a profile
with `position: President` can be reached at the location
`/people#President`, while a profile with `position: VP Academic` can be
reached at location `/people#VP Academic`. In case where there are two
positions with the same name (e.g. two PGSS representatives), the anchor will
be placed on the profile that comes alphabetically first.

### Updating quick links
The front page `_index.html` has quick links. These links are specified in
Markdown files, in the `content/quick-links/` directory, with the following
metadata:
* title (required): Title of the quick link
* link (required): Link to the resource

An example of a quick-link file is presented below:
```
---
name: McGill Society of Physics Students
link: http://msps.sus.mcgill.ca/
---
McGill's offical organisation representing the undergraduates in physics
```

The name of the files in `content/quick-links/` directory are not important.
New quick links can be added by creating markdown files for them.

### Updating files
Files can be hosted on this website, as long as they are stored in the
`/static/files/` folder. Any file in this folder will be included in the
website as-is. These files can be linked to from any Markdown file using the
link syntax, for example:
```
The GA minutes are available [here](/files/ga_minutes_2018.pdf)
```

### Updating images
Images are found in the `/static/images/` directory. Subdirectories, like
`/static/images/profiles/`, are also supported. Currently, the webite will crop
all images to the same dimensions, though this can be changed.

## Local Usage
Building the MGAPS website locally, for testing before publishing to the
official web page, is done using `hugo v0.164.0`. The Hugo installation
process begins [here](https://gohugo.io/installation/). Once installed, simply
navigate to the project root, and run the `hugo` command. The output should 
look like:
```
hugo v0.164.0+extended+withdeploy linux/amd64 BuildDate=unknown


                  │ EN 
──────────────────┼────
 Pages            │ 56 
 Paginator pages  │  0 
 Non-page files   │  0 
 Static files     │ 42 
 Processed images │  0 
 Aliases          │  0 
 Cleaned          │  0 

Total in 639 ms
```
Similarly, `hugo server` will give you a `localhost` link so you may preview 
the local website in your browser to make sure everything is in order. See
`hugo -help` for all other available commands. One benefit of `hugo server` is
that it updates in real-time as you edit the source files, allowing you to
verify your work as you make changes.

The `/public/` directory contains the final website that Hugo builds using
the markdown files. These files are always re-generated when building locally,
and is what is finally served as the official website. These files __should not__
be tracked by git.


## Deployment
__Deployment of the website is automated.__
Simply commit the changes to the website source (in `static/`, `people/`,
etc.). Once changes on the master repository are detected, the following will
happen: 
1. A build server (provided by GitHub) will clone the content of the website;
2. Hugo tools will be installed.
3. Hugo will build the website from the source markdown, HTML, CSS, etc. files.
4. the changes in `/public/` will be committed to appropriate branch.
5. Profit.

