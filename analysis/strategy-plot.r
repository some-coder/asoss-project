INPUT_FILE_NAME <- '../data/strategies.csv'
OUTPUT_FILE_NAME <- '../plots/strategies.pdf'


SIMULATION_TIME <- 2.0e3  # in ticks


CONSTANT_COLUMNS <- c('group_size')
VARIABLES <- c('catches', 'c_over_l')
VBLS_AS_STRINGS <- list(
	'c_over_l'='#catches / #lock-ons',
	'c_over_lt'='#catches / (#lock-ons x T)',
	'catches'='number of fish caught')
VBLS_AS_STRINGS_SHORT <- list(
	'c_over_l'='metric C/L',
	'c_over_lt'='metric C/(LT)',
	'catches'='School size\'s effect on fish caught')
VARIABLE_COLORS <- list(
	'c_over_l'='#e41a1c',
	'c_over_lt'='#377eb8',
	'catches'='#1f78b4')
STRATEGY_NAMES <- list(
	'mixed'='Mixed',
	'cooperative-selfish'='Cooperative-selfish',
	'zig-zag'='Zig-zag',
	'optimal'='Optimal',
	'protean'='Protean',
	'biased'='Biased',
	'refuge'='Refuge',
	'refuge-escape'='Refuge-escape')


load_libraries <- function() {
	lbs <- c('ggplot2', 'cowplot', 'plyr')
	for (lb in lbs) {
		require(lb, character.only=TRUE)
	}
}


summary_frame <- function(dat, vbl) {
	fr <- data.frame(
		'group_size'=factor(x=c(), levels=unique(dat$group_size)),
		'mean'=double(),
		'error'=double())
	cl <- dat$catches / dat$lock_ons
	clt <- dat$catches / (dat$lock_ons * SIMULATION_TIME)
	for (index in 1:length(cl)) {
		# divisions by zero
		cl[index] <- if (is.nan(cl[index])) { 0.0 } else { cl[index] }
		clt[index] <- if (is.nan(clt[index])) { 0.0 } else { clt[index] }
	}
	dat <- cbind(dat, data.frame(
		'c_over_l'=cl,
		'c_over_lt'=clt))
	for (group_size in unique(dat$group_size)) {
		sub_dat <- dat[which(dat$group_size == group_size), ]
		mn <- mean(sub_dat[, vbl])
		se <- sd(sub_dat[, vbl]) / sqrt(nrow(sub_dat))
		fr <- rbind(fr, data.frame(
			'group_size'=group_size,
			'mean'=mn,
			'error'=se))
	}
	return(fr)
}


single_fish_predation_plot <- function(dat, vbl, ttl) {
	map <- aes_string(x='group_size', y='mean')
	fr <- summary_frame(dat, vbl)
	plt <- ggplot(data=fr, mapping=map)
	plt <- plt + geom_line(
		col=VARIABLE_COLORS[[vbl]])
	plt <- plt + geom_errorbar(
		mapping=aes(
			ymin=mean - error,
			ymax=mean + error),
		width=3e0,
		col=VARIABLE_COLORS[[vbl]])
	plt <- plt +
		xlab('Size of fish school') +
		ylab(paste0(
			'Average ',
			VBLS_AS_STRINGS[[vbl]])) +
		labs(
			title=paste0(
				ttl,
				', ',
				VBLS_AS_STRINGS_SHORT[[vbl]]),
			subtitle=paste0(
				'Size of fish school versus average\n    ',
				VBLS_AS_STRINGS[[vbl]],
				'\n    over 10 runs per school size, at 2000 ticks'))
	plt <- plt + scale_x_continuous(
		breaks=c(50, 100, 300),
		minor_breaks=c(25, 75, 125, 150, 175, 200, 225, 250, 275),
		limits=c(2e1, 32e1))
	plt <- plt + scale_y_continuous(
		limits=if (vbl == 'c_over_l') { c(-1e-7, 0.8) } else { c(-1e-7, 0.000555) })
	plt <- plt + theme_light()
	return(plt)
}


group_size_plots <- function(dat, ttl) {
	plots <- list()
	for (vbl in VARIABLES) {
		plots[[length(plots) + 1]] <- single_fish_predation_plot(dat, vbl, ttl)
	}
	return(plots)
}


main <- function() {
	load_libraries()
	dat <- read.csv(INPUT_FILE_NAME)
	lst <- list()
	for (strat in unique(dat$strategy)) {
		plots <- group_size_plots(
			dat[which(dat$strategy == strat), ],
			paste0(
				'Strategy \'',
				STRATEGY_NAMES[[strat]],
				'\''))
		for (index in 1:length(plots)) {
			lst[[length(lst) + 1]] <- plots[[index]]
		}
	}
	grd <- plot_grid(
		plotlist=lst,
		nrow=length(unique(dat$strategy)),
		ncol=length(VARIABLES))
	if (!dir.exists('../plots')) {
		dir.create('../plots')
	}
	ggsave(
		OUTPUT_FILE_NAME,
		plot=grd,
		device='pdf',
		width=9,
		height=26)
	return('Exit success.')
}


main()
