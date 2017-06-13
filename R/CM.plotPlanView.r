#' Plot a map of the channel
#'
#' Create a plan view map of the channel and various elements that can be switched on and off (banks, centerline, transects,
#' grid, legend, etc.).
#'
#' \code{CM.plotPlanView()} creates a plan view plot. To specify the map extent (plot region) multiple settings exist.
#' The map extent is the range of x and y coordinates shown on the map, speaking in R terms the xlim and ylim parameters of the plot function.
#' In \code{CM.plotPlanView()} the map extent is defined by a center coordinate (x and one y coordinate where the plot is centered at), and a zoom length. You have multiple
#' ways to determine the center coordinate: pre-defined extent, cl, error and direct x/y coordinates (see descriptions in the parameters).
#' This list also represents the priority, meaning, the pre-defined extent indicates the lowest priority and x/y coordinates the highest if more than one
#' parameter is set. The zoom length can be given via the global parameter object or directly with the parameter zoom.
#'
#' You can enable/disable the following plotting elements via the paramtere object:\preformatted{
#' plot.planview               = TRUE,        # plot an plan view overview plot
#' plot.planview.secondary     = TRUE,        # plot a secondary channel polygon to the plot (for comparison of data sets)
#' plot.planview.bank.points   = TRUE,        # plot channel bank points
#' plot.planview.polygons      = TRUE,        # plot channel bank polygons
#' plot.planview.voronoi       = TRUE,        # plot voronoi polygons in plan view plot
#' plot.planview.cl.original   = FALSE,       # plot centerline in plan view plot
#' plot.planview.cl.smoothed   = TRUE,        # plot centerline in plan view plot
#' plot.planview.cl.tx         = FALSE,       # plot a label next to the centerline points
#' plot.planview.transects     = FALSE,       # plot transects
#' plot.planview.transects.len = 20,          # the length of transects
#' plot.planview.dist2banks    = TRUE,        # plot transect segments from bank to bank
#' plot.planview.grid          = TRUE,        # plot a grid in the background of the plan view plot
#' plot.planview.grid.dist     = 20,          # the distance of the grid lines
#' plot.planview.legend        = TRUE,        # plot a legend
#' plot.planview.scalebar      = TRUE,        # plot a scalebar
#' }
#'
#'
#' @template param_global_data_object
#' @param set the data set to be plotted, "set1" if not specified. See documentation of CM.ini() to learn about data sets.
#' @param set.compare a second data set to be plotted in light color for comparison
#' @param extent a string defining the plotting extent of the map (specifying an object of the list in par$plot.zoom.extents) or NULL (the default extent of par$plot.zoom.extent is taken)
#' @param zoom defines if plot is zoomed (TRUE) or not (FALSE). In case of NULL (default) the value of par$plot.zoom is taken
#' @param zoom.length a number defining the zoom length
#' @param cl the centerline point or points with should be centered
#' @param error an integer between 1 and <number of errors> (see Details for further information)
#' @param error.type a string specifying which errors should be investigated ("errors.filter2", "errors.filter2.first" or "errors.sort")
#' @param x an x-coordinate where the map is centered at
#' @param y an y-coordinate where the map is centered at
#' @return a list of applied plot parameters (this is useful for plotting the same extent in CM.plotBankShift())
#' @author Antonius Golly
#' @examples
#' # get demo data (find instructions on how to use own data in the documentation of CM.ini())
#' cmgo.obj = CM.ini("demo2")
#'
#' # example 1: overview plot
#' CM.plotPlanView(cmgo.obj)
#'
#' @export CM.plotPlanView

CM.plotPlanView <- function(object, set="set1", set.compare=NULL, extent=NULL, zoom = TRUE, zoom.length = NULL, cl=NULL, error=NULL, error.type="errors.filter2", x=NULL, y=NULL){

  par  = object$par
  data = object$data

  notice    = function(x,prim=FALSE){cat(paste((if(prim) "\n--> " else " "), x, sep=""), sep="\n")}
  plot.file = function(par){if(!par$plot.to.file) return(NULL); file.no   = 0 + par$plot.index; file.name = paste(par$plot.directory, str_pad(file.no, 3, pad="0"), "_", par$plot.filename, sep=""); while(file.exists(paste(file.name, ".png", sep="")) || file.exists(paste(file.name, ".pdf", sep=""))){  file.no   = file.no + 1; file.name = paste(par$plot.directory, str_pad(file.no, 3, pad="0"), "_", par$plot.filename, sep="") }; dev.copy(png, filename=paste(file.name, ".png", sep=""), width=800, height=600); dev.off(); dev.copy2pdf(file=paste(file.name, ".pdf", sep=""));}

  leg.add = function(leg, tx, item=NULL, lwd=1, lty=NA, pch=NA, cex=1, col="black"){

    item = if(is.null(item)) paste("item_", length(leg)+1, sep="") else item

    leg[[item]] = list(
      tx   = tx,
      lwd  = lwd,
      lty  = lty,
      pch  = pch,
      cex  = cex,
      col  = col
    )

    return(leg)

  }

  leg.make = function(leg){

    if(length(leg) == 0) return(NULL)

    tx = type = lwd = lty = pch = cex = col = c()

    for(item in c(1:length(leg))){
      tx   = append(tx,  leg[[item]]$tx)
      lwd  = append(lwd, leg[[item]]$lwd)
      lty  = append(lty, leg[[item]]$lty)
      pch  = append(pch, leg[[item]]$pch)
      cex  = append(cex, leg[[item]]$cex)
      col  = append(col, leg[[item]]$col)
    }

    leg.vec = function(x) return(if(length(unique(x))==1) x[1] else x)

    legend("topleft", inset = 0.05,
      legend = leg.vec(tx),
      lwd    = leg.vec(lwd),
      lty    = leg.vec(lty),
      pch    = leg.vec(pch),
      pt.cex = leg.vec(cex),
      col    = leg.vec(col)
    )
  }

  #dev.new(width=6, height=10)
  par(mfrow=c(1,1))
  notice("create plan view plot", TRUE)

  #for(plot in plots){

    ### get reference sets
    set.ref       = data[[set]]$metrics$cl.ref                       ; if(is.null(set.ref)) set.ref = FALSE
    set.secondary = if(is.null(set.compare)) set.ref else set.compare; if(!is.null(set.secondary)) if(!set.secondary %in% names(data)) set.secondary = NULL
    set.cl.ref    = if(par$plot.cl.range.use.reference) set.ref else set

    # specify zoom
    zoom        = if(is.null(zoom))        par$plot.zoom               else zoom
    zoom.length = if(is.null(zoom.length)) par$plot.zoom.extent.length else zoom.length


    # specify plot extent #####################################################

    # by set
    if(is.null(extent)) extent = par$plot.zoom.extent
    if(typeof(extent) == "character"){ if(extent %in% names(par$plot.zoom.extents)) extent = par$plot.zoom.extents[[extent]] else stop(paste("given zoom extent", extent, "unknown!"))}
    plot.x = extent[1]
    plot.y = extent[2]
    plot.extent.rule = "predefined set"

    # by cl point
    if(!is.null(cl)){
      if(typeof(cl) == "character"){ if(cl %in% names(par$plot.cl.ranges)) cl = par$plot.cl.ranges[[cl]] else stop(paste("given cl range", cl, "unknown!"))}
      if(length(cl) == 2) cl = seq(from = cl[1], to = cl[2]);
      plot.x = data[[set.cl.ref]]$cl$smoothed$x[round(mean(cl))]
      plot.y = data[[set.cl.ref]]$cl$smoothed$y[round(mean(cl))]
      plot.extent.rule = "cl point"
    }

    # by error in centerline generation
    if(!is.null(error)){
      if(!is.null(data[[set]]$cl[[error.type]]) && !is.null(data[[set]]$cl$paths)){
        plot.x = data[[set]]$cl[[error.type]][error,1]
        plot.y = data[[set]]$cl[[error.type]][error,2]
        plot.extent.rule = "centerline path errors"
      } else { print("not all data available to center at errors") }
    }

    # by x coordinate
    if(!is.null(x)){
      plot.x = x; if(is.null(y)) plot.y = data[[set]]$cl$smoothed$y[which.min(abs(data[[set]]$cl$smoothed$x - x))]
      plot.extent.rule = "x-coordinate"
    }

    # by y coordinate
    if(!is.null(y)){
      plot.y = y; if(is.null(x)) plot.x = data[[set]]$cl$smoothed$x[which.min(abs(data[[set]]$cl$smoothed$y - y))]
      plot.extent.rule = if(plot.extent.rule == "x-coordinate") "x/y-coordinates" else "y-coordinate"
    }

    # output to console
    notice(paste("plot extend determined by:", plot.extent.rule))
    notice("to show full extend use CM.plotPlanView(cmgo.obj, zoom=FALSE)", TRUE)
    notice(paste("plot centered at x = ",plot.x, ", y = ", plot.y))

    if(plot.extent.rule == "centerline path errors") notice(paste("selected error", error, "of available error span 1 to", nrow(data[[set]]$cl[[error.type]])))
    leg = list()




    ### create empty plot ###
    plot(0,
      main = paste("Plan view of", set, if(par$plot.planview.secondary){ paste("(solid) and", if(is.null(set.compare)) "reference ", set.secondary, "(dashed)")}),
      xlim = if(zoom) plot.x + c(-0.5 * zoom.length, + 0.5 * zoom.length) else range(data[[set]]$channel$x),
      ylim = if(zoom) plot.y + c(-0.5 * zoom.length, + 0.5 * zoom.length) else range(data[[set]]$channel$y),
      asp=1, type="n", xlab="X", ylab="Y"
    )

    # grid ####################################################################
    if(par$plot.planview.grid){
      abline(v=seq(floor(floor(plot.x - zoom.length)/100)*100, ceiling(ceiling(plot.x + zoom.length)/100)*100, par$plot.planview.grid.dist), col=colors()[356])
      abline(h=seq(floor(floor(plot.y - zoom.length)/100)*100, ceiling(ceiling(plot.y + zoom.length)/100)*100, par$plot.planview.grid.dist), col=colors()[356])
    }

    # voronoi polygons ########################################################
    if(par$plot.planview.voronoi){
      #if(exists("voronoi")) for(tile in voronoi$tiles){ lines(tile$bdry[[1]], col="lightgray")}
      if(!is.null(data[[set]]$cl$paths))           {segments(data[[set]]$cl$paths$x1, data[[set]]$cl$paths$y1, data[[set]]$cl$paths$x2, data[[set]]$cl$paths$y2, col="lightgray"); leg = leg.add(leg, "voronoi polygons", lty=1, col="gray")}
      #if(!is.null(data[[set]]$cl$paths.in.polygon)){segments(data[[set]]$cl$paths.in.polygon$x1, data[[set]]$cl$paths.in.polygon$y1, data[[set]]$cl$paths.in.polygon$x2, data[[set]]$cl$paths.in.polygon$y2, col="red");leg = leg.add(leg, "paths in polygon", lty=1, col="red")}
      #segments(data[[set]]$cl$cl.paths$x1, data[[set]]$cl$cl.paths$y1, data[[set]]$cl$cl.paths$x2, data[[set]]$cl$cl.paths$y2, col="black", lty=3,lwd=2); leg = leg.add(leg, "cl paths (filtered)", lty=3, lwd=2, col="black")}
    }

    # bank points #############################################################
    if(par$plot.planview.bankpoints && !is.null(data[[set]]$channel$x)){
      points(data[[set]]$channel$y ~ data[[set]]$channel$x, pch=19, cex=0.8)
      leg = leg.add(leg, paste("bank points of", set), pch=19, col="black", cex=0.8)
    }

    # channel bank polygons ###################################################
    if(par$plot.planview.polygons && !is.null(data[[set]]$polygon)){
      lines(data[[set]]$polygon$y ~ data[[set]]$polygon$x, col="black")
      leg = leg.add(leg, paste("banks of", set), lty=1, col="black")
    }

    # second polygon for comparison
    if(par$plot.planview.secondary && !is.null(set.secondary)){
      lines( data[[set.secondary]]$polygon$y ~ data[[set.secondary]]$polygon$x, lty=2, col="gray")
      leg = leg.add(leg, paste("banks of", set.secondary), lty=2, col="gray")
    }

    # tr = transects ##########################################################
    if(par$plot.planview.transects && !is.null(data[[set]]$metrics$tr)){
      apply(data[[set]]$metrics$tr, 1, function(x){
        m  = x["m"];  a  = ( ((par$plot.planview.transects.len)^2) / (1 + m^2) ) ^(1/2);  xs = x["Px"] - a;  ys = x["m"] * xs + x["n"]; xe = x["Px"] + a;  ye = x["m"] * xe + x["n"]
        lines(c(xs,xe), c(ys, ye), lty=5, lwd=1.2, col="blue")
      })
      leg = leg.add(leg, "transects", lty=5, lwd=1.2, col="blue")
    }

    # transects halfs #########################################################
    if(par$plot.planview.dist2banks && !is.null(data[[set]]$metrics$tr) && !is.null(data[[set]]$metrics$cp.r) && !is.null(data[[set]]$metrics$cp.l)){
      apply(cbind(data[[set]]$metrics$cp.r[,c(1,2)], data[[set]]$metrics$tr[,c(3,4)]), 1, function(x){  segments(x[1], x[2], x[3], x[4], col="green") })
      apply(cbind(data[[set]]$metrics$cp.l[,c(1,2)], data[[set]]$metrics$tr[,c(3,4)]), 1, function(x){  segments(x[1], x[2], x[3], x[4], col="red")   })
      leg = leg.add(leg, paste("right bank of", set, "to reference of", data[[set]]$metrics$cl.ref), lty=1, col="green")
      leg = leg.add(leg, paste("left bank of",  set, "to reference of", data[[set]]$metrics$cl.ref), lty=1, col="red")
    }

    # centerline ##############################################################
    if(par$plot.planview.cl.original) lines(data[[set]]$cl$original$y  ~ data[[set]]$cl$original$x, col="red", lwd = 1.5)
    if(par$plot.planview.cl.smoothed && !is.null(data[[set]]$cl$smoothed)){
      lines( data[[set]]$cl$smoothed$y ~ data[[set]]$cl$smoothed$x, col="blue",lwd = if(set==set.ref) 2.5 else 1)
      points(data[[set]]$cl$smoothed$y ~ data[[set]]$cl$smoothed$x, cex=0.4, pch=19, col="blue")
      leg = leg.add(leg, paste("centerline of", set, if(set==set.ref)"(reference)"), lty=1, pch=19, lwd = if(set==set.ref) 2.5 else 1, cex=0.4, col="blue")

      # secondary
      if(par$plot.planview.secondary && !is.null(set.secondary) && set.secondary != set){
        lines(data[[set.secondary]]$cl$smoothed$y  ~ data[[set.secondary]]$cl$smoothed$x, lwd = if(set.secondary == set.ref) 2.5 else 1, col="blue")
        points(data[[set.secondary]]$cl$smoothed$y ~ data[[set.secondary]]$cl$smoothed$x, cex=0.4, pch=19, col="blue")
        leg = leg.add(leg, paste("centerline of", set.secondary, if(set.secondary == set.ref) paste("(reference of ", set, ")", sep="")), pch=19, cex=0.4, lwd = if(set.secondary == set.ref) 2.5 else 1, col="blue", lty=1)
      }

      # numbering
      if(par$plot.planview.cl.tx){
        for(i in c(1:length(data[[set]]$cl$smoothed$x)))           text(data[[set]]$cl$smoothed$x[i], data[[set]]$cl$smoothed$y[i]-(par$plot.zoom.extent.length/100), i, cex=0.5)
        if(!is.null(set.secondary)) for(i in c(1:length(data[[set.secondary]]$cl$smoothed$x))) text(data[[set.secondary]]$cl$smoothed$x[i], data[[set.secondary]]$cl$smoothed$y[i]-(par$plot.zoom.extent.length/100), i, cex=0.5, col="gray")
      }

    }

    # cl range ################################################################
    if(!is.null(cl)){
      points(data[[set.cl.ref]]$cl$smoothed$x[cl], data[[set.cl.ref]]$cl$smoothed$y[cl], pch=1, col="orange", cex=1.1)
      leg = leg.add(leg, "cl range selection", pch=1, col="orange", cex=1.1)
    }

    # legend and scale bar ####################################################
    if(par$plot.planview.legend) leg.make(leg)
    if(par$plot.planview.scalebar){
      segments(
        plot.x + 0.5 * zoom.length - par$plot.planview.grid.dist,
        plot.y - 0.5 * zoom.length,
        plot.x + 0.5 * zoom.length,
        plot.y - 0.5 * zoom.length,
        lwd = 15, lend=2
      )
      text(
        plot.x + 0.5 * zoom.length - (0.5 * par$plot.planview.grid.dist),
        plot.y - 0.5 * zoom.length + zoom.length / 30,
        paste(par$plot.planview.grid.dist, "m")
      )
    }

  #} # for(plot in plots)

  plot.file(par)

  notice("plotting done!")

  return(list(
    x   = plot.x,
    y   = plot.y,
    set = set,
    cl  = cl
  ))

}