# Custom grobs that scale their line widths relative the the dimensions
# of the image. For example, lines should be thicker when the image is
# larger.

makeContext.picRect <- function(x) {
    x$gp <- scaleLwd(x$gp)
    x
}

makeContent.picRect <- function(x) {
    rectGrob(x$x, x$y, x$width, x$height,
             just = x$just, gp = x$gp, vp=x$vp,
             name = x$name,
             default.units = x$default.units)
}

picRectGrob <- function(x, y, width, height, just, gp, default.units, vp=NULL) {
    grob(x = x, y = y, width = width, height = height,
         just = just, gp = gp, default.units = default.units, vp = vp,
         cl = "picRect")
}

makeContent.picPath <- function(x) {
    pathGrob(x$x, x$y, id.lengths = x$id.lengths, rule = x$rule,
             name = x$name,
             gp = x$gp, default.units = x$default.units)
}

picPathGrob <- function(x, y, id.lengths, rule, gp, default.units) {
    grob(x = x, y = y, id.lengths = id.lengths, rule = rule,
         gp = gp, default.units = default.units, cl = "picPath")
}

makeContent.picPolyline <- function(x) {
    polylineGrob(x$x, x$y, id.lengths = x$id.lengths,
                 name = x$name,
                 gp = x$gp, default.units = x$default.units)
}

picPolylineGrob <- function(x, y, id.lengths, gp, default.units) {
    grob(x = x, y = y, id.lengths = id.lengths,
         gp = gp, default.units = default.units,
         cl = "picPolyline")
}

makeContext.picComplexPath <- function(x) {
    x$gp <- scaleLwd(x$gp)
    x
}

picComplexPathGrob <- function(linePoints, pathPoints,
                               lineIDLengths, pathIDLengths,
                               rule, gp) {
    gTree(children = gList(
        picPathGrob(unlist(pathPoints$x), unlist(pathPoints$y),
                    id.lengths = pathIDLengths,
                    rule = rule, gp = gpar(col = "#FFFFFF00"),
                    default.units = "native"),
        picPolylineGrob(unlist(linePoints$x), unlist(linePoints$y),
                        id.lengths = lineIDLengths,
                        gp = gpar(fill = "#FFFFFF00"),
                        default.units = "native")
    ), gp = gp, cl = "picComplexPath")
}

scaleLwd <- function(gp) {
    lwd <- gp$lwd
    lty <- gp$lty
    # Calculate the current "resolution"
    res <- 96 # pdf, png, jpeg, postscript, all 1/96 per lwd
    scaleFactor <-
        res * min(abs(convertWidth(unit(1, "native"),
                                   "inches", valueOnly = TRUE)),
                  abs(convertHeight(unit(1, "native"),
                                    "inches", valueOnly = TRUE)))
    if (! is.null(lwd))
        lwd <- lwd * scaleFactor

    # FIXME CONSIDER CASE WHEN LWD IS NOT PRESENT
    if (! is.null(lty))
        lty <- paste(as.hexmode(pmax(pmin(round((lty * scaleFactor) / lwd), 15), 1)),
                     collapse = "")

    gp$lwd <- lwd
    gp$lty <- lty
    gp
}

# Apply gridSVG features to grid grobs
# FIXME: Make this more efficient by using registration
gridSVGAddFeatures <- function(grob, gp, 
                               mask = character(0),
                               filter = character(0)) {
    gparNames <- names(gp)
    if ("gradientFill" %in% gparNames) {
        gradDef <- getDef(gp$gradientFill)
        if (! is.null(gradDef)) {
            # Assume a fillAlpha of 1 because there will be no
            # fill property (due to gradient being there instead)
            fillAlpha <- 1
            grob <- gridSVG::gradientFillGrob(grob,
                                     label = prefixName(gp$gradientFill),
                                     alpha = fillAlpha)
        }
    }
    if ("gradientStroke" %in% gparNames) {
        # Do nothing, not supported by gridSVG (yet)
        #def <- getDef(defs, gp$gradientStroke)
    }
    if ("patternFill" %in% gparNames) {
        patDef <- getDef(gp$patternFill)
        if (! is.null(patDef)) {
            fillAlpha <- 1
            grob <- gridSVG::patternFillGrob(grob,
                                    label = prefixName(gp$patternFill),
                                    alpha = fillAlpha)
        }
    }
    if ("patternStroke" %in% gparNames) {
        # Do nothing, not supported by gridSVG (yet)
        #def <- getDef(defs, gp$patternStroke)
    }
    # Now for masks and filters
    if (length(mask))
        grob <- gridSVG::maskGrob(grob, label = prefixName(mask))
    if (length(filter))
        grob <- gridSVG::filterGrob(grob, label = prefixName(filter))
    grob
}

resolvePictureSize <- function(width, height, xscale, yscale, distort) {
    if (is.null(width)) {
        if (is.null(height)) {
            if (distort) {
                width <- unit(1, "npc")
                height <- unit(1, "npc")
            } else {
                pictureRatio <- abs(diff(yscale))/
                    abs(diff(xscale))
                vpWidth <- convertWidth(unit(1, "npc"), "inches",
                                        valueOnly=TRUE)
                vpHeight <- convertHeight(unit(1, "npc"), "inches",
                                          valueOnly=TRUE)
                vpRatio <- vpHeight/vpWidth
                if (pictureRatio > vpRatio) {
                    height <- unit(vpHeight, "inches")
                    width <- unit(vpHeight*
                                  abs(diff(xscale))/
                                  abs(diff(yscale)),
                                  "inches")
                } else {
                    width <- unit(vpWidth, "inches")
                    height <- unit(vpWidth*
                                   abs(diff(yscale))/
                                   abs(diff(xscale)),
                                   "inches")
                }
            }
        } else {
            if (distort) {
                width <- unit(1, "npc")
            } else {
                h <- convertHeight(height, "inches", valueOnly=TRUE)
                width <- unit(h*
                              abs(diff(xscale))/
                              abs(diff(yscale)),
                              "inches")
            }
        }
    } else {
        if (is.null(height)) {
            if (distort) {
                height <- unit(1, "npc")
            } else {
                w <- convertWidth(width, "inches", valueOnly=TRUE)
                height <- unit(w*
                               abs(diff(yscale))/
                               abs(diff(xscale)),
                               "inches")
            }
        }
    }
    list(width=width, height=height)
}

# Viewport from picture
pictureVP <- function(picture, expansion = 0.05,
                      x, y, width, height,
                      just, hjust, vjust,
                      xscale = NULL, yscale = NULL,
                      distort = FALSE, clip = "on", ...) {
    if (is.null(xscale) || is.null(yscale)) {
        xscale <- picture@summary@xscale
    	yscale <- picture@summary@yscale
    }
    xscale <- xscale + expansion * c(-1, 1) * diff(xscale)
    yscale <- yscale + expansion * c(-1, 1) * diff(yscale)

    wh <- resolvePictureSize(width, height, xscale, yscale, distort)

    # If distort=TRUE, having the two layers of viewports is
    # massively redundant, BUT I'm keeping it so that either
    # way there is the same viewport structure, which I think
    # is beneficial if anyone ever wants to make use of
    # these viewports (otherwise they would need to figure
    # out whether a picture grob has one or two viewports).
    vpStack(viewport(name = "picture.shape", ...,
                     x = x, y = y, width = wh$width, height = wh$height,
                     just = c(resolveHJust(just, hjust),
                              resolveVJust(just, vjust)),
                     layout = grid.layout(1, 1,
                                          widths = abs(diff(xscale)),
                                          heights = abs(diff(yscale)),
                                          respect = ! distort)),
            viewport(name = "picture.scale",
                     layout.pos.col = 1,
                     xscale = xscale,
                     yscale = yscale,
                     clip = clip,
                     ## Enforce SVG defaults
                     ## https://oreillymedia.github.io/Using_SVG/guide/style.html
                     gp = gpar(col=NA, fill="black")))
}

clipVP <- function(xscale, yscale) {
    # Note: SVG y-scales are reversed
    viewport(x = xscale[1], y = yscale[2],
             width = abs(diff(xscale)), height = abs(diff(yscale)),
             xscale = xscale, yscale = yscale,
             default.units = "native", just = c("left", "top"),
             clip = "on")
}

registerDefs <- function(defs, ext) {
    content <- defs@content
    ids <- names(content)
    for (i in seq_len(length(content))) {
        def <- content[[i]]
        label <- prefixName(ids[i])
        if (is(def, "PicturePattern")) {
            gridSVG::registerPatternFill(label, grobify(def, ext=ext))
        } else if (is(def, "PictureFilter")) {
            gridSVG::registerFilter(label, grobify(def, ext=ext))
        } else if (is(def, "PictureMask")) {
            gridSVG::registerMask(label, grobify(def, ext=ext))
        } else if (is(def, "PictureClipPath")) {
            gridSVG::registerClipPath(label,
                                      gridSVG::clipPath(grobify(def, ext=ext)))
        } else if (is(def, "PictureLinearGradient") ||
                   is(def, "PictureRadialGradient")) {
            gridSVG::registerGradientFill(label, grobify(def, ext=ext))
        } else {
            warning("Some definitions not registered")
            ## if (nchar(system.file(package="ggplot2")) &&
            ##     packageVersion("gridSVG") > "1.7-5") {
            ##     gridSVG::registerDef(label, grobify(def, ext=ext))
            ## } else {
            ##     warning("Some definitions not registered")
            ## }
        }
    }
}
