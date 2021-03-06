#####################################################
####Boosting and Backfitting Tutorial
#####################################################
source("data_prep.R")
source("shiny_boosting_demo.R")

####run the shiny application
shinyApp( ui = dashboardPage(header,sidebar,body), server = server)

####################################################
####Now lets make this more realistic
####And use the mboost package
####to specify other base learners
####################################################

###first lets do the prior example with the mboost package
###start with the linear regression model using least squares

mu=c(1,2)#mean of simulated data
sig=matrix(c(1,0,0,2),nrow=2,byrow=T)
x<-mvrnorm(n=1000,mu=mu,Sigma=sig)
y<-1.5+3*x[,1]+rnorm(nrow(x),mean=0,sd=1) ###make simple association with x1
data=data.frame(x=x[,1],y=y)

lm <- lm(y~x,data=data)
coef(lm)

###boosted version
glm1 <- glmboost(y~x,data=data,control=boost_control(mstop=100))
coef(glm1,off2int = T)
###look at coefficient paths as a function of boosting iterations
plot(glm1,off2int = T)

###Now lets say we didn't know that X2 was inactive
data<-data.frame(y=y,x)
glm1 <- glmboost(y~.,data=data,control=boost_control(mstop=100))
coef(glm1,off2int = T)
###look at coefficient paths as a function of boosting iterations
plot(glm1,off2int = T)
###this did a nice job of regularization


#######Less of a toy problem
mu=c(1,2)#mean of simulated data
sig=matrix(c(1,0,0,2),nrow=2,byrow=T)
x<-mvrnorm(n=1000,mu=mu,Sigma=sig)
y<-1.5+3*sin(2*pi*x[,1])+rnorm(nrow(x),mean=0,sd=1) ###make simple association with x1

data=data.frame(x,y)
ggplot(data,aes(x=X1,y=y))+geom_point()+ggtitle("Scatterplot of Y vs X")

gam1 <- gamboost(y~bols(X1)+bols(X2,intercept=F),data=data)
coef(gam1,off2int = T)
###not very good
preds <- data.frame(f_x=predict(gam1),data.frame(model.frame(gam1))["X1"]) %>% arrange(X1)
ggplot(data,aes(x=X1,y=y))+geom_point()+
  ggtitle("Fit to Data of Linear Bols") +
  geom_line(data=preds,aes(x=X1,y=f_x))

####lets do a spline basis for X1 & X2
gam1 <- gamboost(y~bols(X1)+bols(X2)+bbs(X1,df=20)+bbs(X2,df=20),data=data)
plot(gam1)
###better
preds <- data.frame(f_x=predict(gam1),data.frame(model.frame(gam1))["X1"]) %>% arrange(X1)
ggplot(data,aes(x=X1,y=y))+geom_point()+
  ggtitle("Fit to Data of Spline Bols") +
  geom_line(data=preds,aes(x=X1,y=f_x))


###we can also do this using trees
###the gbm package is better for this
###fit a boosted model
gbm1 <-
  gbm(y~X1+X2,         # formula
      data=data,                   # dataset
      var.monotone=c(0,0), # -1: monotone decrease,
      # +1: monotone increase,
      #  0: no monotone restrictions
      distribution="gaussian",     # see the help for other choices
      n.trees=1000,                # number of trees
      shrinkage=0.025,              # shrinkage or learning rate,
      # 0.001 to 0.1 usually work
      interaction.depth=3,         # 1: additive model, 2: two-way interactions, etc.
      bag.fraction = 0.5,          # subsampling fraction, 0.5 is probably best
      train.fraction = 0.5,        # fraction of data for training,
      # first train.fraction*N used for training
      n.minobsinnode = 10,         # minimum total weight needed in each node
      cv.folds = 3,                # do 3-fold cross-validation
      keep.data=TRUE,              # keep a copy of the dataset with the object
      verbose=FALSE,               # don't print out progress
      n.cores=1)                   # use only a single core (detecting #cores is


# check performance using 3-fold cross-validation
best.iter <- gbm.perf(gbm1,method="cv")
print(best.iter)


# plot the performance # plot variable influence
summary(gbm1,n.trees=1)         # based on the first tree
summary(gbm1,n.trees=best.iter) # based on the estimated best number of trees

# compactly print the first and last trees for curiosity
print(pretty.gbm.tree(gbm1,1))
print(pretty.gbm.tree(gbm1,gbm1$n.trees))

# create marginal plots
# plot variable X1,X2 after "best" iterations
par(mfrow=c(1,2))
plot(gbm1,1,best.iter)
plot(gbm1,2,best.iter)
par(mfrow=c(1,1))


preds <- data.frame(f_x=predict(gbm1),X1=data$X1) %>% arrange(X1)
ggplot(data,aes(x=X1,y=y))+geom_point()+
  ggtitle("Fit to Data of Tree Basis Bols") +
  geom_line(data=preds,aes(x=X1,y=f_x))



####################################################
####Boosting using trees with GBM package
####For our exact problem
####################################################
source("data_prep.R")

###construct weights function for full model
###to be fit at once
weights <-as.data.frame(table(TRAIN$Race,TRAIN$Productivity))
weights$weight <- unlist(lapply(weights$Freq,function(x){
  1/x
}))

TRAIN$Weight <- 0
for (r in weights$Var1){
  for(p in weights$Var2){
    w <- weights$weight[ weights$Var1==r & weights$Var2==p]
    TRAIN$Weight[ TRAIN$Race==r & TRAIN$Productivity==p] <- w
  }
}


###fit a boosted model
gbm1 <-
  gbm(Productivity~H1+H2+Race,         # formula
      data=TRAIN,                   # dataset
      var.monotone=c(0,0,0), # -1: monotone decrease,
      # +1: monotone increase,
      #  0: no monotone restrictions
      weights=Weight,
      distribution="multinomial",     # see the help for other choices
      n.trees=1000,                # number of trees
      shrinkage=0.01,              # shrinkage or learning rate,
      # 0.001 to 0.1 usually work
      interaction.depth=3,         # 1: additive model, 2: two-way interactions, etc.
      bag.fraction = 0.5,          # subsampling fraction, 0.5 is probably best
      train.fraction = 0.5,        # fraction of data for training,
      # first train.fraction*N used for training
      n.minobsinnode = 10,         # minimum total weight needed in each node
      cv.folds = 3,                # do 3-fold cross-validation
      keep.data=TRUE,              # keep a copy of the dataset with the object
      verbose=FALSE,               # don't print out progress
      n.cores=1)                   # use only a single core (detecting #cores is
# # error-prone, so avoided here)
# # check performance using an out-of-bag estimator
# # OOB underestimates the optimal number of iterations
# best.iter <- gbm.perf(gbm1,method="OOB")
# print(best.iter)
# 
# # check performance using a 50% heldout test set
# best.iter <- gbm.perf(gbm1,method="test")
# print(best.iter)

# check performance using 5-fold cross-validation
best.iter <- gbm.perf(gbm1,method="cv")
print(best.iter)

# plot the performance # plot variable influence
summary(gbm1,n.trees=1)         # based on the first tree
summary(gbm1,n.trees=best.iter) # based on the estimated best number of trees

# compactly print the first and last trees for curiosity
print(pretty.gbm.tree(gbm1,1))
print(pretty.gbm.tree(gbm1,gbm1$n.trees))

# create marginal plots
# plot variable X1,X2,X3 after "best" iterations
par(mfrow=c(1,3))
plot(gbm1,1,best.iter)
plot(gbm1,2,best.iter)
plot(gbm1,3,best.iter)
par(mfrow=c(1,1))
# contour plot of variables 1 and 2 after "best" iterations
#plot(gbm1,1:2,best.iter)
# lattice plot of variables 2 and 3
###3 way plot
#plot(gbm1,1:3,best.iter)
# do another 100 iterations

#best.iter=1000
bestmod<-gbm1


###Plot the linear fit
######Plot 2-D grid of Classification Rule
create_grid<-function(x1,x2,n=1000){
  min_x1<-min(x1)
  max_x1<-max(x1)
  x1_seq<-seq(min_x1,max_x1,length.out=floor(sqrt(n)))
  min_x2<-min(x2)
  max_x2<-max(x2)
  x2_seq<-seq(min_x2,max_x2,length.out=floor(sqrt(n)))
  grid<-expand.grid(H1=x1_seq,H2=x2_seq)
  return(grid)
}

grid<-create_grid(DATA$H1,DATA$H2,n=10000)


par_disp<-unique(TRAIN$Race)
race=par_disp[2]

###look at the latent funciton F(X) that is squished by the sigmoid softmax function

for(race in par_disp){
  CUT_TEST<-TEST[TEST$Race==race, ]
  grid$Race=CUT_TEST$Race[1]
  func=predict(bestmod,newdata = grid,best.iter,type ="link" )
  func<-data.frame(grid,func)
  tmp<-predict(bestmod,newdata=CUT_TEST,best.iter,type="response")
  class<-apply(tmp,1,function(b){
    which(b==max(b))
  })
  class<-colnames(tmp)[class]
  concordance<-numeric(length(class))
  for (i in 1:nrow(CUT_TEST)){
    concordance[i]=as.numeric(CUT_TEST$Productivity[i] %in% class[i])                                   
  }
  correct<-round(mean(concordance),3)*100
  
  
  plot_dat<-melt(func,id=c("H1","H2","Race"))
  cols <- rev(brewer.pal(11, 'RdYlBu'))
  plot<-ggplot(data=plot_dat,aes(x=H1,y=H2,fill=value))+
    geom_tile()+
    stat_contour(data=plot_dat,aes(z=value))+
    ggtitle(paste("Latent Logit for",race,"Percent Correct=",correct,"%"))+
    facet_wrap(~variable,ncol=2)+ scale_fill_gradientn(colours = cols)
  print(plot)  
}



###look at the response surface after applying the softmax function

for(race in par_disp){
  CUT_TEST<-TEST[TEST$Race==race, ]
  grid$Race=CUT_TEST$Race[1]
  func=predict(bestmod,newdata = grid,best.iter,type ="response" )
  func<-data.frame(grid,func)
  tmp<-predict(bestmod,newdata=CUT_TEST,best.iter,type="response")
  class<-apply(tmp,1,function(b){
    which(b==max(b))
  })
  class<-colnames(tmp)[class]
  concordance<-numeric(length(class))
  for (i in 1:nrow(CUT_TEST)){
    concordance[i]=as.numeric(CUT_TEST$Productivity[i] %in% class[i])                                   
  }
  correct<-round(mean(concordance),3)*100
  
  
  plot_dat<-melt(func,id=c("H1","H2","Race"))
  cols <- rev(brewer.pal(11, 'RdYlBu'))
  plot<-ggplot(data=plot_dat,aes(x=H1,y=H2,fill=value))+
    geom_tile()+
    stat_contour(data=plot_dat,aes(z=value))+
    ggtitle(paste("Probability Distribution for",race,"Percent Correct=",correct,"%"))+
    facet_wrap(~variable,ncol=2)+ scale_fill_gradientn(colours = cols)
  print(plot)  
}




####################################
####Work with bartMachine Package (this is better than the BayesTree package)
####bartMachine  uses rJava to use a complied language for the run (way faster)
####plus it has a predict funciton that BayesTree lacks
####Lets look at some genomic data
####################################
source("data_prep.R")

###pull in a balanced data set of genomic expression
###for non-balanced you should be using weights
###unless you expect your margin to come into play
###with regards to your loss function
data(promotergene)
summary(promotergene)
x=promotergene %>% select(-Class)
y=promotergene %>% select(Class)
y=y$Class



####use the BartMachine pacakge to fit models
###you have to set the java heap early on (fyi) before the first rJava call
set_bart_machine_num_cores(4)
fit <- bartMachineCV(X=x,y=y)
summary(fit)
gc()


####look at convergence
plot_convergence_diagnostics(fit)

####look at posterior distribution
predict(fit,x[1,],type="prob")
predict(fit,x[1,],type="class")
calc_credible_intervals(fit,x[1,],ci_conf=0.95)###CI for mean function E(Y|x)=f(x)

####check out importance of different variables
investigate_var_importance(fit,num_var_plot = 50)
cov_importance_test(fit)###omnibus test
cov_importance_test(fit, covariates = c("V18"))###test V18 after adjustment for other covariates


####variable importance inclusion criteria
vs <- var_selection_by_permute(fit,bottom_margin = 10,num_permute_samples = 10,num_var_plot = 20)
vs$important_vars_local_names
vs$important_vars_global_max_names
vs$important_vars_global_se_names


#####check for interactions
interaction_investigator(fit,num_replicates_for_avg = 25,num_var_plot = 10, bottom_margin = 20)



####look at partial depencence effect
pd_plot(fit,j=10)




###check the fit on k-fold cross validation
oos_stats <- k_fold_cv(X=x,y=y,k_folds = 5,prob_rule_class=0.9)###set an unreasonable rule default is 0.5
oos_stats$confusion_matrix




###lets generate an ROC curve as a function of the prob_rule_classification parameter
###this will help us select the best model for our purposes
###to do this we need to think a bit about loss and pick a function that meets our goals
###if we want equal misclassification costs, the parameter value should be the upper left elbow
###in the curve

###change probability rule for classification
prob_rule <- seq(0,1,by=0.1)
i=prob_rule[1]
ROC_Data <- data.frame()
for(i in prob_rule){
  fit_roc <- bartMachine(X=x,y=y,prob_rule_class=1-i)
  print(fit_roc$confusion_matrix)
  tmp <- data.frame(
    "DecisionRuleForPositive"=round(i,2),
    "TruePosRate"=1-fit_roc$confusion_matrix$"model errors"[1],
    "FalsePosRate"=fit_roc$confusion_matrix$"model errors"[2])
  ROC_Data <- bind_rows(ROC_Data,tmp)
}


datatable(ROC_Data,options = list(pageLength=nrow(ROC_Data)))
rPlot(TruePosRate~FalsePosRate,data=ROC_Data,type="point")








