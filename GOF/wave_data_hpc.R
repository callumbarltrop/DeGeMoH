# Functions and packages --------------------------------------------------

rm(list=ls())

library(SphericalCubature)
library(parallel)
library(movMF)
library(ggplot2)
library(MASS)
library(ragg)
library(GGally)

compute_orthant_proportions <- function(data) {
  if (!is.data.frame(data) && !is.matrix(data)) {
    stop("data must be a data frame or matrix")
  }
  
  n_dim <- ncol(data)
  
  get_sign_vector <- function(row) {
    return(ifelse(row >= 0, 1, -1))
  }
  
  sign_matrix <- t(apply(data, 1, get_sign_vector))
  
  sign_df <- as.data.frame(sign_matrix)
  for (i in 1:n_dim) {
    sign_df[, i] <- factor(sign_df[, i], levels = c(-1, 1), labels = c("-1", "1"))
  }
  
  sign_counts <- table(sign_df)
  
  sign_proportions <- sign_counts / nrow(data)
  
  return(sign_proportions)
}

ang_dist = function(w_a,w_b){ #for calculating angular distances
  cos_theta = sum(w_a*w_b)
  cos_theta = min(max(cos_theta,-1),1) #helps with numerical stability, avoiding any numerical errors
  return(acos(cos_theta))
}

# Function to calculate pairwise angular distances in parallel
parallel_ang_dist <- function(i,pseudo_angles_sim) {
  sum(apply(expand.grid(i, 1:nrow(pseudo_angles_sim)), 1, function(row) {
    ang_dist(pseudo_angles_sim[row[1], ], pseudo_angles_sim[row[2], ])
  }))
}

CRPS_function = function(w_ref,sim_angles,second_term){
  first_term = mean(apply(sim_angles,1, ang_dist,w_a = w_ref))
  
  return(first_term - second_term)
}

full_data = read.table(file="shuffled_data.txt")

d = ncol(full_data)

proportion_train = 0.2

train_data = full_data[1:(round(nrow(full_data)*proportion_train)),]

valid_data = full_data[(round(nrow(full_data)*proportion_train) + 1):nrow(full_data),]

polar_valid = rect2polar(t(valid_data))

tran_indx = which(polar_valid$phi[d-1,] > pi)

polar_valid$phi[d-1,tran_indx] = polar_valid$phi[d-1,tran_indx] - 2*pi

pseudo_angles_train = train_data/rect2polar(t(train_data))$r

if(!file.exists(file="wavedata_paras.rds")){
  mix_fit <- movMF(x = as.matrix(pseudo_angles_train), k = 100, nruns = 10)

  est_theta = mix_fit$theta

  est_alpha = mix_fit$alpha

  saveRDS(list(est_theta = est_theta,est_alpha=est_alpha),file="wavedata_paras.rds")
}

mix_fit = readRDS(file="wavedata_paras.rds")

est_theta = mix_fit$est_theta

est_alpha = mix_fit$est_alpha

set.seed(1)

pseudo_angles_sim <- as.matrix(rmovMF(1e5,est_theta,est_alpha))

polar_sim <- rect2polar(t(pseudo_angles_sim))

tran_indx = which(polar_sim$phi[d-1,] > pi)

polar_sim$phi[d-1,tran_indx] = polar_sim$phi[d-1,tran_indx] - 2*pi

polar_sim = t(polar_sim$phi)

data <- data.frame(rbind(t(polar_valid$phi),polar_sim[1:100000,])) 

names(data) = c("Theta_1","Theta_2","Theta_3","Theta_4")
plot_names = c("Theta[1]","Theta[2]","Theta[3]","Theta[4]")

empty_panel <- function(data, mapping) {
  ggplot(data = data, mapping = mapping) +
    theme_void() # Use a void theme to make it empty
}

empty_panel2 <- function(data, mapping) {
  if(as.character(mapping) == "~Theta_1"){ 
    # Data for the legend
    legend_data <- data.frame(
      category = c("Observed", "Generated"),
      color = c("grey", rgb(0, 1, 0,alpha=0.2)),
      shape = c(16, 16)
    )
    
    ggplot() +
      
      geom_point(aes(x = 0, y = 0), alpha = 0, size = 0) +
      
      annotate("point", x = 0, y = 0.5, color = legend_data$color[1], shape = legend_data$shape[1], size = 3) +
      annotate("text", x = 0.1, y = 0.5, label = legend_data$category[1], hjust = 0,size=3) +
      
      annotate("point", x = 0, y = 0, color = legend_data$color[2], shape = legend_data$shape[2], size = 3) +
      annotate("text", x = 0.1, y = 0, label = legend_data$category[2], hjust = 0,size=3) +

      xlim(-0.5, 1) +
      ylim(-1, 1) +
      theme_void() +
      theme(legend.position = "center") 
  } else {
    ggplot(data = data, mapping = mapping) +
      theme_void()  
  }
  
}

custom_lower_plot <- function(data, mapping) {
  xvar <- as.character(mapping$x)
  yvar <- as.character(mapping$y)
  if(as.character(mapping$y)[[2]] == "Theta_4"){
    ggplot(data = data, mapping = mapping) +
      geom_point(alpha = c(rep(1,length(polar_valid$r)),rep(0.2,100000)), size = 0.7,color = c(rep("grey",length(polar_valid$r)),rep(rgb(0, 1, 0),100000))) +
      coord_cartesian(xlim = c(0,pi),ylim=c(-pi,pi)) +
      theme_minimal()
  } else {
    ggplot(data = data, mapping = mapping) +
      geom_point(alpha = c(rep(1,length(polar_valid$r)),rep(0.2,100000)), size = 0.7,color = c(rep("grey",length(polar_valid$r)),rep(rgb(0, 1, 0),100000))) +
      coord_cartesian(xlim = c(0,pi),ylim=c(0,pi)) +
      theme_minimal()
  }
  
}

your_plot <- ggpairs(data,
                     lower = list(continuous = wrap(custom_lower_plot)),
                     upper = list(continuous = wrap(empty_panel)),
                     diag = list(continuous = wrap(empty_panel2)),
                     columnLabels = plot_names,
                     labeller = label_parsed)

ggsave("wavedata_scatter.png", your_plot,
       width = 8, height = 8, units = "in",
       device = ragg::agg_png, dpi = 300)

labels2 <- sapply(1:(d-2), function(i) bquote(Theta[.(i)]))

labels2 <- c(labels2,bquote((Theta[.(d-1)] + pi)/2))

pdf(file="wavedata_qqplot_diagnostic.pdf",width=5,height=5)

par(mfrow=c(1,1))

model_cols = c("green","blue","purple","orange")

for(i in 1:ncol(t(polar_valid$phi))){
  data1 <- t(polar_valid$phi)[,i]
  data2 <- polar_sim[,i]
  
  if(i == d-1){
    data1 <- (data1+pi)/2
    data2 <- (data2+pi)/2
  }
  
  title = bquote(Theta[.(i)])
  
  m = 10000
  
  probs = (1:m)/(m+1)

  if(i == 1){
    plot(quantile(data1,probs=probs)[1], quantile(data2,probs=probs)[1],xlim=c(0,pi),ylim=c(0,pi),
         main = "Spherical angles QQ plots",
         xlab = "Observed", ylab = "Generated",pch=1,col="black",cex.lab=1.3, cex.axis=1.2,cex.main=1.8)
    
    points(quantile(data1,probs=probs), quantile(data2,probs=probs),pch=16,col=model_cols[i])
    
  } else {
    
    points(quantile(data1,probs=probs), quantile(data2,probs=probs),pch=16,col=model_cols[i])
    
  }
  abline(0, 1, col = "red",lwd=4)
}

legend("topleft",col = model_cols,cex=1.5,legend=labels2,pch=16)

dev.off()

labels <- sapply(1:(d-1), function(i) bquote(Theta[.(i)]))

pdf(file="wavedata_histogram_diagnostic.pdf",width=12,height=3)

par(mfrow=c(1,4))

for(i in 1:ncol(t(polar_valid$phi))){
  data1 <- t(polar_valid$phi)[,i]
  data2 <- polar_sim[,i]

  breaks <- seq(min(data1, data2), max(data1, data2), length.out = 30)

  hist(data1, breaks = breaks, freq = FALSE, col = rgb(0, 0, 1, 0.5),
       main = labels[i], xlab = "Value", ylab = "Density", border = "blue",cex.lab=1.3, cex.axis=1.2,cex.main=1.8)

  hist(data2, breaks = breaks,sub="", freq = FALSE, col = rgb(1, 0, 0, 0.5), add = TRUE, border = "red")

  if(i == 4){
    legend("topleft", legend = c("Observed", "Generated"),
           col = c(rgb(0, 0, 1, 0.5), rgb(1, 0, 0, 0.5)), pch = 15,cex = 1.3,bg="white")
  }

}

dev.off()

pdf(file="wavedata_orthant_prob_diagnostic.pdf",width=5,height=5)

par(mfrow=c(1,1))

orthant_props_big <- compute_orthant_proportions(valid_data)

orthant_props_est <- compute_orthant_proportions(t(polar2rect(r=rep(1,nrow(polar_sim)),phi=t(polar_sim))))

orthant_props_big <- c(orthant_props_big)
orthant_props_est <- c(orthant_props_est)

plot(log(orthant_props_big+1),log(orthant_props_est+1),pch=16,col="grey",cex.lab=1.3, cex.axis=1.2,cex.main=1.5,xlim=range(log(orthant_props_big+1),log(orthant_props_est+1)),ylim=range(log(orthant_props_big+1),log(orthant_props_est+1)),xlab = "Observed",ylab = "Generated",sub="log(p + 1)",main="Orthant probability estimates")
abline(a=0,b=1,lwd=4,col=2)
points(log(orthant_props_big+1),log(orthant_props_est+1),pch=16,col="black",cex=1.3)

dev.off()

pseudo_angles_valid = valid_data/polar_valid$r

cl <- makeCluster(detectCores()-1)  # Adjust the number of cores as needed
clusterExport(cl, c("ang_dist"))

sum_diff = parLapply(cl, 1:nrow(pseudo_angles_sim), parallel_ang_dist, pseudo_angles_sim=pseudo_angles_sim)

second_term <- 0.5*(sum(unlist(sum_diff)))/((nrow(pseudo_angles_sim))^2)

CRPS_vec = parApply(cl,pseudo_angles_valid,1,CRPS_function,sim_angles = pseudo_angles_sim,second_term = second_term)

stopCluster(cl)

exp_CRPS = mean(CRPS_vec)

saveRDS(list(crps = exp_CRPS,crps_vec = CRPS_vec),file = "wavedata_crps.rds")
