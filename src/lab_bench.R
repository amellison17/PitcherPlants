###The Lab Bench 
###Pitcher Plant projects
###MKLau 13May2014

###How is ascendency affected by connectance?
##Load a model
##Randomly remove a flow
##Calculate connectence (links/spp^2)
##Calculate ascendency

library(enaR)

rm.node <- function(x){
  y <- x%n%'flow'
  if (sum(abs(y))!=0){
    rnd.r <- (1:nrow(y))[apply(abs(y),1,sum)!=0]
    if (length((1:ncol(y))[abs(y[rnd.r,])!=0])==1){
      rnd.r <- (1:nrow(y))[apply(abs(y),1,sum)!=0]
      rnd.c <- (1:ncol(y))[abs(y[rnd.r,])!=0]
    }else{
      rnd.r <- sample((1:nrow(y))[apply(abs(y),1,sum)!=0],1)
      rnd.c <- sample((1:ncol(y))[abs(y[rnd.r,])!=0],1)
    }
    y[rnd.r,rnd.c] <- 0
    x%n%'flow' <- y
  }
  return(x)
}

data(enaModels)
data(enaModelInfo)
select <- unlist(lapply(enaModels,function(x) 
                        ((all(is.na(x%v%'export')==FALSE)
                          &
                          all((is.na(x%v%'respiration')==FALSE))
                          )
                         )
                        )
                 )
select <- (select==TRUE&enaModelInfo=='trophic')
out <- list()
for (k in 1:length(select[select==TRUE])){
x <- enaModels[select][[k]]
x.name <- names(enaModels[select])[k]
rm.x <- x
asc <- 0
con <- 0
for (i in 1:(length((x%n%'flow')[(x%n%'flow')!=0]))){
  if (length((rm.x%n%'flow')[(rm.x%n%'flow')!=0])==1){
    asc[i] <- 0
    con[i] <- 0
  }else{
    asc[i] <- enaAscendency(rm.x)[2]
    con[i] <- enaStructure(rm.x)$ns[3]
    rm.x <- rm.node(rm.x)
  }
}
out[[k]] <- cbind(con,asc)
print(k)
}

names(out) <- names(enaModels[select])
dput(out,file='../results/CvsA.R')
###plot
k <- 1
plot(out[[k]],type='l',ylim=c(0,max(do.call(rbind,out)[,2])),xlim=c(0,max(do.call(rbind,out)[,1])))
for (k in 2:length(out)){
  lines(out[[k]])
}
out.cor <- unlist(lapply(out,function(x) cor(x)[1,2]))
hist(out.cor)
plot(density(out.cor))

names(out)[out.cor<=0]

plot(out$'Lake Findley ',type='l')
plot(out$'Swartkops Estuary  15',type='l')

###Preliminary Hawley analysis looking for temporal trends.
####Data are NOT published. Do not distribute
###(a1=open, a2=plug 3 weeks and a3=plug 6 weeks)

h99 <- read.csv('./data/Hawley1999colonization.csv')
h99 <- h99[,-ncol(h99)]
h99[is.na(h99)] <- 0
                                        #limit to open pitchers
h99 <- h99[h99$treatment=='a1',]
                                        #fix date error
h99$date[h99$date=='19997020'] <- '19990720'
                                        #split individual obs
h99 <- split(h99,paste(h99[,1],h99[,2],h99[,3],h99[,5]))
                                        #matricizing
h99.com <- matrix(0,nrow=length(h99),ncol=length(unique(h99[[1]]$inquiline)))
colnames(h99.com) <- unique(h99[[1]]$inquiline)
for (i in 1:length(h99)){
  for (j in 1:nrow(h99[[i]])){
    h99.com[i,colnames(h99.com)==h99[[i]][j,4]] <- h99[[i]][j,6]
  }
}
                                        #order by species name
h99.com <- h99.com[,order(colnames(h99.com))]
                                        #get environmental info
h99.env <- do.call(rbind,lapply(names(h99),function(x) unlist(strsplit(x,split=' '))))
colnames(h99.env) <- c('trt','plant','leaf','date')
                                        #make date an date vector
h99.env[,4] <- paste(substr(h99.env[,4],1,4),substr(h99.env[,4],5,6),substr(h99.env[,4],7,8),sep='-')
h99.date <- as.Date(h99.env[,4])
                                        #plot of species dynamics across sampling dates
png('./results/h99_time.png',width=600,height=600)
par(mfrow=c(3,3))
for (i in 1:ncol(h99.com)){
  plot(h99.com[,i]~h99.date,main=colnames(h99.com)[i])
  lines(spline(h99.com[,i]~h99.date))
}
dev.off()
                                        #pairs plot
source('/Users/Aeolus/projects/dissertation/projects/lcn/docs/LCO_analyses/source/pairs.R')
png('./results/h99_pairs.png',width=600,height=600)
pairs(h99.com,lower.panel=panel.cor,upper.panel=panel.lm)
dev.off()
                                        #temporal pattern for a single species
head(h99.env);tail(h99.env)
tpl <- paste(h99.env[,1],h99.env[,2],h99.env[,3]) #treatment plant leaf
tpl.date <- split(h99.env[,4],tpl)
tpl.date <- lapply(tpl.date,as.Date)
                                        #plot all species all pitchers
png('./results/h99_temporal.png',width=600,height=600)
par(mfrow=c(3,3))
for (k in 1:ncol(h99.com)){
  i <- 1
  h99.tpl <- split(I(h99.com[,k]/max(h99.com[,k])),tpl)
  plot(h99.tpl[[i]]~tpl.date[[k]],xlab='Date',ylab=colnames(h99.com)[k],type='l',ylim=c(-0.25,1))
  for (i in 2:length(h99.tpl)){
    lines(spline(h99.tpl[[i]]~tpl.date[[k]]))
  }
}
dev.off()
pdf('./results/h99_temporal.pdf')
par(mfrow=c(3,3))
for (k in 1:ncol(h99.com)){
  i <- 1
  h99.tpl <- split(I(h99.com[,k]/max(h99.com[,k])),tpl)
  plot(h99.tpl[[i]]~tpl.date[[k]],xlab='Date',ylab=colnames(h99.com)[k],type='l',ylim=c(-0.25,1))
  for (i in 2:length(h99.tpl)){
    lines(spline(h99.tpl[[i]]~tpl.date[[k]]))
  }
}
dev.off()

###Molly
h99 <- read.csv('./data/Molly1999colonization.csv')
h99 <- h99[,-ncol(h99)]
h99[is.na(h99)] <- 0
                                        #limit to open pitchers
h99 <- h99[h99$treatment=='a1',]
                                        #fix date error
h99$date[h99$date=='19997020'] <- '19990720'
                                        #split individual obs
h99 <- split(h99,paste(h99[,1],h99[,2],h99[,3],h99[,5]))
                                        #matricizing
h99.com <- matrix(0,nrow=length(h99),ncol=length(unique(h99[[1]]$inquiline)))
colnames(h99.com) <- unique(h99[[1]]$inquiline)
for (i in 1:length(h99)){
  for (j in 1:nrow(h99[[i]])){
    h99.com[i,colnames(h99.com)==h99[[i]][j,4]] <- h99[[i]][j,6]
  }
}
                                        #order by species name
h99.com <- h99.com[,order(colnames(h99.com))]
                                        #get environmental info
h99.env <- do.call(rbind,lapply(names(h99),function(x) unlist(strsplit(x,split=' '))))
colnames(h99.env) <- c('trt','plant','leaf','date')
                                        #make date an date vector
h99.env[,4] <- paste(substr(h99.env[,4],1,4),substr(h99.env[,4],5,6),substr(h99.env[,4],7,8),sep='-')
h99.date <- as.Date(h99.env[,4])
                                        #plot of species dynamics across sampling dates
png('./results/m99_time.png',width=600,height=600)
par(mfrow=c(3,3))
for (i in 1:ncol(h99.com)){
  plot(h99.com[,i]~h99.date,main=colnames(h99.com)[i])
  lines(spline(h99.com[,i]~h99.date))
}
dev.off()
                                        #pairs plot
source('/Users/Aeolus/projects/dissertation/projects/lcn/docs/LCO_analyses/source/pairs.R')
png('./results/m99_pairs.png',width=600,height=600)
pairs(h99.com,lower.panel=panel.cor,upper.panel=panel.lm)
dev.off()
                                        #temporal pattern for a single species
head(h99.env);tail(h99.env)
tpl <- paste(h99.env[,1],h99.env[,2],h99.env[,3]) #treatment plant leaf
tpl.date <- split(h99.env[,4],tpl)
tpl.date <- lapply(tpl.date,as.Date)
                                        #plot all species all pitchers
png('./results/m99_temporal.png',width=600,height=600)
par(mfrow=c(3,3))
for (k in 1:ncol(h99.com)){
  i <- 1
  h99.tpl <- split(I(h99.com[,k]/max(h99.com[,k])),tpl)
  plot(h99.tpl[[i]]~tpl.date[[k]],xlab='Date',ylab=colnames(h99.com)[k],type='l',ylim=c(-0.25,1))
  for (i in 2:length(h99.tpl)){
    lines(spline(h99.tpl[[i]]~tpl.date[[k]]))
  }
}
dev.off()
pdf('./results/m99_temporal.pdf')
par(mfrow=c(3,3))
for (k in 1:ncol(h99.com)){
  i <- 1
  h99.tpl <- split(I(h99.com[,k]/max(h99.com[,k])),tpl)
  plot(h99.tpl[[i]]~tpl.date[[k]],xlab='Date',ylab=colnames(h99.com)[k],type='l',ylim=c(-0.25,1))
  for (i in 2:length(h99.tpl)){
    lines(spline(h99.tpl[[i]]~tpl.date[[k]]))
  }
}
dev.off()
