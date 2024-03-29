# Import some S3 classes
setOldClass("gpar")
setOldClass("nativeRaster")

# We need to be able to transform objects when we create them
# we can do this via a transformation matrix acting upon the original object
setGeneric("applyTransform",
           function(object, tm) {
               standardGeneric("applyTransform")
           })

# Method useful for tracking the bounding boxes of the content of the image.
# Mostly useful for being able to reduce a picture and its bounding box
# to only a subset of the image.
setGeneric("getbbox",
           function(object, tm) {
               standardGeneric("getbbox")
           })

# Method for turning a picture object into a grid graphics object
setGeneric("grobify",
           function(object, ...) {
               standardGeneric("grobify")
           })

setGeneric("symbolize",
           function(object,
                    x = unit(0.5, "npc"),
                    y = unit(0.5, "npc"),
                    size = unit(1, "npc"),
                    default.units = "npc",
                    ...) {
               standardGeneric("symbolize")
           })

# Empty base class, just ensures that we can test whether
# children are valid pieces of a picture
setClass("PictureContent")

setClass("PictureClipPath",
         representation("PictureContent",
                        content = "list",
                        label = "character"))
setValidity("PictureClipPath",
            function(object) {
                length(object@content) &&
                all(sapply(object@content, is, "PictureContent"))
            })

setClass("PictureFeImage",
         representation("PictureContent",
                        href = "character",
                        result = "character",
                        x = "numeric",
                        y = "numeric",
                        width = "numeric",
                        height = "numeric"))

setClass("PictureFeComposite",
         representation("PictureContent",
                        input1 = "character",
                        input2 = "character",
                        operator = "character",
                        k1 = "numeric",
                        k2 = "numeric",
                        k3 = "numeric",
                        k4 = "numeric",
                        colorspace = "character"))
         
setClass("PictureFeColorMatrix",
         representation("PictureContent",
                        type = "character",
                        input = "character",
                        values = "matrix",
                        colorspace = "character"))

setClass("PictureFilter",
         representation("PictureContent",
                        filterUnits = "character",
                        primitiveUnits = "character",
                        x = "numeric", y = "numeric",
                        width = "numeric", height = "numeric",
                        content = "list"))

setClass("PictureGroup",
         representation("PictureContent",
                        content = "list",
                        clip = "ANY",
                        maskRef = "ANY",
                        filterRef = "ANY",
                        gp = "gpar"))

setValidity("PictureGroup",
            function(object) {
                # mask and filter can be ["NULL"|"character"]
                if (! is.null(object@maskRef) &&
                    ! is.character(object@maskRef)) return(FALSE)
                if (! is.null(object@filterRef) &&
                    ! is.character(object@filterRef)) return(FALSE)
                # Must have content and only "PictureContent".
                # Furthermore, only allow no clipping or a clipping path
                # object, essentially the representation of 'clip' is 
                # ["NULL"|"PictureClipPath"].
                if (length(object@content))
                    all(sapply(object@content, is, "PictureContent")) &&
                    (is.null(object@clip) ||
                     is(object@clip, "PictureClipPath"))
                else
                    (is.null(object@clip) ||
                     is(object@clip, "PictureClipPath"))
            })

setClass("PictureImage",
         representation("PictureContent",
                        x = "numeric",
                        y = "numeric",
                        width = "numeric",
                        height = "numeric",
                        angle = "numeric",
                        image = "nativeRaster",
                        maskRef = "ANY",
                        bbox = "numeric"))

setClass("PictureMask",
         representation("PictureContent",
                        content = "list"))
setValidity("PictureMask",
            function(object) {
                length(object@content) &&
                all(sapply(object@content, is, "PictureContent"))
            })

# See paths.R for path segments and methods
# Definition of PathData must come before PicturePath
setClass("PathData",
         representation(segments = "list"))
setValidity("PathData",
            function(object) {
                all(sapply(object@segments, is, "PathSegment"))
            })

setClass("PicturePath",
         representation("PictureContent",
                        d = "PathData",
                        rule = "character",
                        gp = "gpar",
                        bbox = "numeric"))

setClass("PicturePattern",
         representation("PictureContent",
                        x = "numeric",
                        y = "numeric",
                        width = "numeric",
                        height = "numeric",
                        angle = "numeric",
                        definition = "list"))

setClass("PictureRadialGradient",
         representation("PictureContent",
                        x = "numeric",
                        y = "numeric",
                        r = "numeric",
                        fx = "numeric",
                        fy = "numeric",
                        spreadMethod = "character",
                        stops = "list"))
setValidity("PictureRadialGradient",
            function(object) {
                all(sapply(object@stops, is, "PictureGradientStop"))
            })

setClass("PictureLinearGradient",
         representation("PictureContent",
                        x0 = "numeric",
                        y0 = "numeric",
                        x1 = "numeric",
                        y1 = "numeric",
                        spreadMethod = "character",
                        stops = "list"))
setValidity("PictureLinearGradient",
            function(object) {
                all(sapply(object@stops, is, "PictureGradientStop"))
            })

setClass("PictureGradientStop",
         representation(offset = "numeric",
                        col = "character"))

setClass("PictureRect",
         representation("PictureContent",
                        x = "numeric",
                        y = "numeric",
                        width = "numeric",
                        height = "numeric",
                        angle = "numeric",
                        gp = "gpar",
                        bbox = "numeric"))

setClass("PictureSymbol",
         representation("PictureContent",
                        definition = "list"))

# Content should be a named list
setClass("PictureDefinitions",
         representation(content = "list"),
         prototype(content = list()))

setGeneric("getDef",
           function(id) standardGeneric("getDef"))

setMethod("getDef",
          signature(id = "character"),
          function(id) {
              defList <- get("defs", .grImport2Env)
              defList@content[[id]]
          })

setGeneric("setDef",
           function(id, value) standardGeneric("setDef"))

setMethod("setDef",
          signature(id = "character",
                    value = "PictureContent"),
          function(id, value) {
              defList <- get("defs", .grImport2Env)
              defList@content[[id]] <- value
              assign("defs", defList, .grImport2Env)
          })

setClass("PictureSummary",
         representation(xscale = "numeric",
                        yscale = "numeric"))

setClass("Picture",
         representation(content = "list",
                        defs = "PictureDefinitions",
                        summary = "PictureSummary"))

setValidity("Picture",
            function(object) {
                all(sapply(object@content, is, "PictureContent"))
            })

setMethod("[", "Picture",
          function(x, i, j, drop) {
              content <- x@content[i]
              allBounds <- lapply(content, getbbox)
              xmin <- min(sapply(allBounds, function(x) x[1]))
              xmax <- max(sapply(allBounds, function(x) x[2]))
              ymin <- min(sapply(allBounds, function(x) x[3]))
              ymax <- max(sapply(allBounds, function(x) x[4]))
              bbox <- c(xmin, xmax, ymin, ymax)
              summary <- new("PictureSummary",
                             xscale = bbox[1:2],
                             yscale = rev(bbox[3:4]))
              new("Picture",
                  content = content,
                  defs = x@defs,
                  summary = summary)
          })

setMethod("[[", "Picture",
          function(x, i, j, drop) {
              if (length(i) > 1)
                  stop("index must be length 1")
              x@content[[i]]
          })

setMethod("[", "PictureGroup",
          function(x, i, j, drop) {
              content <- x@content[i]
              new("PictureGroup",
                  content = content,
                  clip = x@clip,
                  gp = x@gp)
          })

setMethod("[[", "PictureGroup",
          function(x, i, j, drop) {
              if (length(i) > 1)
                  stop("index must be length 1")
              x@content[[i]]
          })

# This is different from applyTransform() method for "PictureLinearGradient"
# This one works from a *reference* (by name) to a "PictureLinearGradient"
# that already exists in a list of definitions, so has to do the look up
# using the name to get a "PictureLinearGradient"
# (actually it is more general than that because it could be working with
#  a radial gradient fill or a pattern fill, not just a linear gradient fill)
# The existing definition is modified to create a new definition, with
# a new name, and the new name (reference to the new definition) is returned
# NOTE that if the name does not identify a known definition then the
# function silently returns the old name
transformRegisteredDef <- function(id, tm) {
    def <- getDef(id)
    if (! is.null(def)) {
        newDef <- applyTransform(def, tm)
        newId <- updateId(id)
        setDef(newId, newDef)
        id <- newId
    }
    id
}

## Different again because need to transform the clip path itself
## and the registered definition 
transformClipPath <- function(cp, tm) {
    id <- cp@label
    def <- getDef(id)
    if (! is.null(def)) {
        newDef <- applyTransform(def, tm)
        newId <- updateId(id)
        setDef(newId, newDef)
        cp@label <- newId
    }
    applyTransform(cp, tm)
}

setMethod("applyTransform",
          signature(object = "gpar",
                    tm = "matrix"),
          function(object, tm) {
              gparNames <- names(object)
              ul <- matrix(c(0, 1/sqrt(2), 0, 1/sqrt(2), rep(1, 2)), ncol = 3)
              for (i in seq_len(nrow(ul)))
                  ul[i, ] <- tm %*% ul[i, ]
              scaleFactor <- sqrt((ul[1, 1] - ul[2, 1])^2 +
                                  (ul[1, 2] - ul[2, 2])^2)
              if ("lwd" %in% gparNames)
                  object$lwd <- abs(object$lwd * scaleFactor)
              if ("lty" %in% gparNames)
                  object$lty <- abs(object$lty * scaleFactor)
              if ("gradientFill" %in% gparNames)
                  object$gradientFill <-
                      transformRegisteredDef(object$gradientFill, tm)
              if ("patternFill" %in% gparNames)
                  object$patternFill <-
                      transformRegisteredDef(object$patternFill, tm)
              object 
          })

setMethod("applyTransform",
          signature(object = "PictureLinearGradient",
                    tm = "matrix"),
          function(object, tm) {
              locs <- matrix(c(object@x0,
                               object@x1,
                               object@y0,
                               object@y1,
                               rep(1, 2)),
                             ncol = 3)
              for (i in seq_len(nrow(locs)))
                  locs[i, ] <- tm %*% locs[i, ]
              object@x0 <- locs[1, 1]
              object@y0 <- locs[1, 2]
              object@x1 <- locs[2, 1]
              object@y1 <- locs[2, 2]
              object
          })

setMethod("applyTransform",
          signature(object = "PictureRadialGradient",
                    tm = "matrix"),
          function(object, tm) {
              locs <- matrix(c(object@x,
                               object@fx,
                               object@y,
                               object@fy,
                               rep(1, 2)),
                             ncol = 3)
              for (i in seq_len(nrow(locs)))
                  locs[i, ] <- tm %*% locs[i, ]
              ## Just interested in scaling (not translation) for radius
              tm[,3] <- c(0, 0, 1)
              ## (assuming no shear)
              tr <- tm %*% c(object@r, 0, 1)
              object@x <- locs[1, 1]
              object@y <- locs[1, 2]
              object@fx <- locs[2, 1]
              object@fy <- locs[2, 2]
              object@r <- sqrt(tr[1]^2 + tr[2]^2)
              object 
          })

setGeneric("transformPatternContent",
           function(object, tm) standardGeneric("transformPatternContent"))

setMethod("transformPatternContent",
          signature(object = "PictureImage",
                    tm = "matrix"),
          function(object, tm) {
              object@width <- object@width*tm[1, 1]
              object@height <- object@height*tm[2, 2]
              object
          })

setMethod("transformPatternContent",
          signature(object = "ANY",
                    tm = "matrix"),
          function(object, tm) {
              object
          })

setMethod("applyTransform",
          signature(object = "PicturePattern",
                    tm = "matrix"),
          function(object, tm) {
              object@definition <- lapply(object@definition,
                                          transformPatternContent, tm)
              object <- transformRect(object, tm)
              object 
          })

setMethod("applyTransform",
          signature(object = "PictureGroup",
                    tm = "matrix"),
          function(object, tm) {
              object@content <- lapply(object@content, applyTransform, tm)
              object@gp <- applyTransform(object@gp, tm)
              ## If there is a clip path or a mask, also transform those
              if (!is.null(object@clip)) {
                  object@clip <- transformClipPath(object@clip, tm)
              }
              if (length(object@maskRef)) {  ## !(NULL or character(0))
                  object@maskRef <- transformRegisteredDef(object@maskRef, tm)
              }
              object
          })
              
setMethod("applyTransform",
          signature(object = "PictureClipPath",
                    tm = "matrix"),
          function(object, tm) {
              object@content <- lapply(object@content, applyTransform, tm)
              object
          })
              
setMethod("applyTransform",
          signature(object = "PictureMask",
                    tm = "matrix"),
          function(object, tm) {
              object@content <- lapply(object@content, applyTransform, tm)
              object
          })
              
# Really only need to be applied to the path data itself
setMethod("applyTransform",
          signature(object = "PicturePath",
                    tm = "matrix"),
          function(object, tm) {
              object@d <- applyTransform(object@d, tm)
              object@gp <- applyTransform(object@gp, tm)
              points <- getPoints(object@d, line = TRUE)
              object@bbox <- c(min(points$x), max(points$x),
                               min(points$y), max(points$y))
              object
          })

transformRect <- function(object, tm) {
    # Get new x, y, width, height, and angle from
    # original x, y, width, height, and transform
    ## https://math.stackexchange.com/questions/13150/extracting-rotation-scale-values-from-2d-transformation-matrix
    a <- tm[1, 1]
    b <- tm[1, 2]
    c <- tm[2, 1]
    d <- tm[2, 2]
    e <- tm[1, 3]
    f <- tm[2, 3]    
    delta <- a * d - b * c
    translation <- c(e, f)
    if (a != 0 || b != 0) {
        r <- sqrt(a * a + b * b)
        rotation <- if (b > 0) acos(a / r) else -acos(a / r)
        scale <- c(r, delta / r)
        skew <- c(atan((a * c + b * d) / (r * r)), 0)
    } else if (c != 0 || d != 0) {
        s <- sqrt(c * c + d * d)
        rotation <- pi / 2 -
            if (d > 0) acos(-c / s) else -acos(c / s)
        scale <- c(delta / s, s)
        skew <- c(0, atan((a * c + b * d) / (s * s)))
    } else {
        ## a = b = c = d = 0
        warning("Zero transformation matrix")
    }
    if (any(skew != 0)) {
        warning("Skew transformation matrix")
    }
    object@x <- object@x + translation[1]
    object@y <- object@y + translation[2]
    object@width <- scale[1]*object@width
    object@height <- scale[2]*object@height
    object@angle <- object@angle + rotation
    object
}

ALTtransformRect <- function(object, tm) {
    # Get new x, y, width, height, and angle from
    # original x, y, width, height, and transform
    loc <- tm %*% c(object@x, object@y, 1)
    object@x <- loc[1, 1]
    object@y <- loc[2, 1]
    sx <- sqrt(tm[1, 1]^2 + tm[1, 2]^2)
    if (tm[1, 1] < 0)
        sx <- -sx
    sy <- sqrt(tm[2, 1]^2 + tm[2, 2]^2)
    if (tm[2, 2] < 0)
        sy <- -sy
    object@width <- sx*object@width
    object@height <- sy*object@height
    # Remove translation
    tm[1, 3] <- 0
    tm[2, 3] <- 0
    # Remove scaling
    tm[1, 1] <- tm[1, 1]/sx
    tm[1, 2] <- tm[1, 2]/-sy
    tm[2, 1] <- tm[2, 1]/sx
    tm[2, 2] <- tm[2, 2]/sy
    # Rotate (1, 0) = positive x-axis to get angle
    loc <- tm %*% c(1, 0, 1)
    angle <- atan2(loc[2, 1], loc[1, 1])
    object@angle <- object@angle + angle
    object
}

transformRectBBox <- function(object, tm) {
    locs <- matrix(c(object@x,
                     object@x + object@width,
                     object@x,
                     object@x + object@width,
                     object@y,
                     object@y + object@height,
                     object@y + object@height,
                     object@y,
                     rep(1, 4)),
                   ncol = 3)
    for (i in seq_len(nrow(locs)))
        locs[i, ] <- tm %*% locs[i, ]
    c(min(locs[, 1]), max(locs[, 1]), min(locs[, 2]), max(locs[, 2]))
}

setMethod("applyTransform",
          signature(object = "PictureRect",
                    tm = "matrix"),
          function(object, tm) {
              # Must transform bbox before transforming object itself
              # (which modifies object's x,y,width,height)
              object@bbox <- transformRectBBox(object, tm)
              object <- transformRect(object, tm)
              object@gp <- applyTransform(object@gp, tm)
              object 
          })

setMethod("applyTransform",
          signature(object = "PictureImage",
                    tm = "matrix"),
          function(object, tm) {
              # Must transform bbox before transforming object itself
              # (which modifies object's x,y,width,height)
              object@bbox <- transformRectBBox(object, tm)
              object <- transformRect(object, tm)
              ## If there is a mask, also transform that
              if (length(object@maskRef)) {  ## !(NULL or character(0))
                  object@maskRef <- transformRegisteredDef(object@maskRef, tm)
              }
              object 
          })

setMethod("applyTransform",
          signature(object = "Picture",
                    tm = "matrix"),
          function(object, tm) {
              content <- lapply(object@content, applyTransform, tm)
              defs <- new("PictureDefinitions",
                          content = lapply(object@defs@content,
                                           applyTransform, tm))
              allBounds <- lapply(content, getbbox)
              xmin <- min(sapply(allBounds, function(x) x[1]))
              xmax <- max(sapply(allBounds, function(x) x[2]))
              ymin <- min(sapply(allBounds, function(x) x[3]))
              ymax <- max(sapply(allBounds, function(x) x[4]))
              bbox <- c(xmin, xmax, ymin, ymax)
              summary <- new("PictureSummary",
                             xscale = bbox[1:2],
                             yscale = rev(bbox[3:4]))
              new("Picture",
                  content = content,
                  defs = defs,
                  summary = summary)
          })

getbboxFromList <- function(x) {
    allBounds <- lapply(x, getbbox)
    xmin <- min(sapply(allBounds, function(x) x[1]))
    xmax <- max(sapply(allBounds, function(x) x[2]))
    ymin <- min(sapply(allBounds, function(x) x[3]))
    ymax <- max(sapply(allBounds, function(x) x[4]))
    c(xmin, xmax, ymin, ymax)
}

setMethod("getbbox",
          signature(object = "list"),
          function(object) {
              getbboxFromList(object)
          })
              
setMethod("getbbox",
          signature(object = "PictureClipPath"),
          function(object) {
              getbboxFromList(object@content)
          })

setMethod("getbbox",
          signature(object = "PictureImage"),
          function(object) {
              object@bbox
          })

setMethod("getbbox",
          signature(object = "PictureRect"),
          function(object) {
              object@bbox
          })

setMethod("getbbox",
          signature(object = "PictureGroup"),
          function(object) {
              getbboxFromList(object@content)
          })

setMethod("getbbox",
          signature(object = "PicturePath"),
          function(object) {
              object@bbox
          })

