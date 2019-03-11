#---------------- �Ǘ���l�v�Z�̂��߂̊֐� ------------------------
# ref.F
ref.F <- function(
  res, # VPA�̌��ʂ̃I�u�W�F�N�g
  sel=NULL, # ���肷��I�𗦁DNULL�̏ꍇ�Cres$Fc.at.age���g����
  waa=NULL, # ���肷�鐶���p�����[�^�D���ڂ̒l�����邩�C�N���w�肷������̂ǂ���ł������B���ڎw�肷��ق����D��B
  maa=NULL,
  M=NULL,
  waa.catch=NULL,
  M.year=NULL, 
  waa.year=NULL, # �N���w�肵�Đ����p�����[�^�����肷��ꍇ�D�N�͈̔͂̕��ϒl���p������DNULL�̏ꍇ�CVPA�ŏI�N�̒l���g����
  maa.year=NULL,
  rps.year = NULL, # Fmed�̌v�Z�Ɏg��RPS�̔N�͈̔́DNULL�̏ꍇ�C�S�͈͂��p������
  max.age = Inf, # �����N����O�΂Ƃ����Ƃ��ɁASPR�v�Z�ōl�������ő�̔N��i�N��̐��ł͂Ȃ����Ƃɒ��Ӂj�B�����N��P�Έȏ�̂Ƃ��́ASPR�v�Z�ōl���������N��-�����N�����͂���A�܂���min.age�̈����ɉ����N���ݒ肷��B
  min.age = 0, # �����N�0�΂łȂ��Ƃ��Ɏw��ł���
  d = 0.001,
  Fspr.init = 0.5, # F%SPR�̏����l
  Fmax.init = 1.5, # Fmax�̏����l
  F0.1.init = 0.7, # F0.1�̏����l
  pSPR = seq(10,90,by=10), # F%SPR���v�Z����Ƃ��́�SPR
  iterlim=1000,
  plot=TRUE,
  Pope=FALSE, # 2014.7.4�ǉ�
  F.range = seq(from=0,to=2,length=101)  # YPR, SPR�Ȑ��������Ƃ���F�͈̔�
){

    argname <- ls()
    arglist <- lapply(argname,function(x) eval(parse(text=x)))
    names(arglist) <- argname
  
  naa <- res$naa
  ssb <- res$ssb
  ny <- ncol(naa)
  years <- dimnames(naa)[[2]]
  ages <- dimnames(naa)[[1]]

  if(is.null(sel)){
    Fc.at.age <- res$Fc.at.age
    sel <- Fc.at.age/max(Fc.at.age,na.rm=TRUE)
  }
  else{
    Fc.at.age <- sel
  }
  sel <- sel/max(sel,na.rm=T)
    
  na <- sum(!is.na(sel))

  if(is.null(waa.year)) waa.year <- rev(years)[1]
  if(is.null(maa.year)) maa.year <- rev(years)[1]
  if(is.null(M.year)) M.year <- rev(years)[1]
  if(is.null(rps.year)) rps.year <- as.numeric(colnames(res$naa))
  
  if(is.null(waa))  waa <- apply(as.matrix(as.data.frame(res$input$dat$waa)[as.character(waa.year)]),1,mean)
  if(is.null(M))  M <- apply(as.matrix(as.data.frame(res$input$dat$M)[as.character(M.year)]),1,mean)
  if(is.null(maa))  maa <- apply(as.matrix(as.data.frame(res$input$dat$maa)[as.character(maa.year)]),1,mean)

  if(is.null(waa.catch)){
      if(is.null(res$input$dat$waa.catch)){
          waa.catch <- waa
      }
      else{
          waa.catch <- apply(as.matrix(as.data.frame(res$input$dat$waa.catch)[as.character(waa.year)]),1,mean)
          }
  }

  ssb.coef <- ifelse(is.null(res$ssb.coef),0,res$ssb.coef)
    
  min.age <- min(as.numeric(rownames(res$naa)))
  if(min.age==0) slide.tmp <- TRUE else slide.tmp <- -1:-min.age
  rps.data <- data.frame(year=as.numeric(names(colSums(ssb,na.rm=T))),
                         ssb=as.numeric(colSums(ssb,na.rm=T)),
                         recruit=as.numeric(c(naa[1,slide.tmp],rep(NA,min.age))))
  if (sum(is.na(rps.data$year))>0) rps.data <- rps.data[-which(is.na(rps.data$year)),]
  rps.data$rps <- rps <- rps.data$recruit/rps.data$ssb
#  rps <- as.numeric(naa[1,]/colSums(ssb,na.rm=TRUE))

#  if (is.null(rps.year)) rps.year <- years

  tmp <- rps.data$year %in% rps.year
  rps.q <- quantile(rps[tmp], na.rm=TRUE, probs=c(0.1,0.5,0.9))
  rps.q <- c(rps.q,mean(rps[tmp], na.rm=TRUE))  
  names(rps.q)[4] <- "mean"
  spr.q <- 1/rps.q

#  browser()
  # F.spr

  spr.f.est <- function(log.p, out=FALSE, sub="med", spr0=NULL){
    Fr <- exp(log.p)

    tmp <- calc.rel.abund(sel,Fr,na,M,waa,waa.catch,maa,min.age=min.age,max.age=max.age,Pope=Pope,ssb.coef=ssb.coef)
    rel.abund <- tmp$rel.abund
    spr <- sum(tmp$spr)
    if (isTRUE(out)) obj <- spr
    else{
     if(sub=="mean") obj <- (spr-spr.q[4])^2       
     if(sub=="low") obj <- (spr-spr.q[3])^2 
     if(sub=="med") obj <- (spr-spr.q[2])^2
     if(sub=="high") obj <- (spr-spr.q[1])^2
     if(is.numeric(sub)) obj <- (spr/spr0-sub/100)^2

    }

    return(obj)
  }

  spr0 <- spr.f.est(-Inf, out=TRUE)

  Fmed.res <- nlm(spr.f.est, Fspr.init, out=FALSE, sub="med", iterlim = iterlim)
  Fmean.res <- nlm(spr.f.est, Fspr.init, out=FALSE, sub="mean", iterlim = iterlim)
#  browser()
  Flow.res <- nlm(spr.f.est, Fspr.init, out=FALSE, sub="low", iterlim = iterlim)
  Fhigh.res <- nlm(spr.f.est, Fspr.init, out=FALSE, sub="high", iterlim = iterlim)

  Fmean <- exp(Fmean.res$estimate)  
  Fmed <- exp(Fmed.res$estimate)
  Flow <- exp(Flow.res$estimate)
  Fhigh <- exp(Fhigh.res$estimate)

  if (!is.null(pSPR)){
    FpSPR <- NULL

    for (i in pSPR){
      FpSPR.res <- nlm(spr.f.est, Fspr.init, out=FALSE, sub=i, spr0=spr0, iterlim=iterlim)
#      print(FpSPR.res)
#       cat("i", FpSPR.res$code," ")
      FpSPR <- c(FpSPR, exp(FpSPR.res$estimate))
    }
    names(FpSPR) <- paste(pSPR,"%SPR",sep="")
  }

  # Fmax

  ypr.f.est <- function(log.p, out=FALSE){
    Fr <- exp(log.p)
  
    tmp <- calc.rel.abund(sel,Fr,na,M,waa,waa.catch,maa,max.age=max.age,Pope=Pope,ssb.coef=ssb.coef)
    rel.abund <- tmp$rel.abund
    ypr <- sum(tmp$ypr)    

    if (isTRUE(out)) obj <- ypr else obj <- -ypr

   return(obj)
  }

  Fmax.res <- nlm(ypr.f.est, log(Fmax.init), out=FALSE)

  Fmax <- exp(Fmax.res$estimate)

  # F0.1

  Fp <- function(log.p, out=FALSE){
    Fr <- exp(log.p)

    tmp <- calc.rel.abund(sel,Fr,na,M,waa,waa.catch,maa,max.age=max.age,Pope=Pope,ssb.coef=ssb.coef)
    rel.abund <- tmp$rel.abund
    ypr <- sum(tmp$ypr)
    if (isTRUE(out)) obj <- ypr else obj <- -ypr

    return(obj)
  }

  F0.1.est <- function(log.p){
    p <- exp(log.p)
    ref.trend <- (Fp(log(d))-Fp(log(0)))/d
    trend <- (Fp(log(p+d)) - Fp(log(p)))/d

    obj <- (ref.trend/10 - trend)^2

    obj
  }

  F0.1.res <- nlm(F0.1.est,log(F0.1.init))
 
  F0.1 <- exp(F0.1.res$estimate)

  # Fcurrent
  Fcurrent <- c(max(Fc.at.age,na.rm=T), mean(Fc.at.age,na.rm=T))
  
  # output
  f.mean <- function(x) mean(x*sel, na.rm=T)

  Fmean <- c(Fmean, f.mean(Fmean))  
  Fmed <- c(Fmed, f.mean(Fmed))
  Flow <- c(Flow, f.mean(Flow))
  Fhigh <- c(Fhigh, f.mean(Fhigh))
  Fmax <- c(Fmax, f.mean(Fmax))
  F0.1 <- c(F0.1, f.mean(F0.1))

  names(Fcurrent) <- names(Fmed) <- names(Fmean) <- names(Flow) <- names(Fhigh) <- names(Fmax) <- names(F0.1) <- c("max","mean")

  Res <- list(sel=sel, min.age=min.age, max.age=max.age, rps.q=rps.q, spr.q=spr.q, Fcurrent=Fcurrent, Fmed=Fmed, Flow=Flow, Fhigh=Fhigh, Fmax=Fmax, F0.1=F0.1, Fmean=Fmean,rps.data=rps.data)
  
  if (!is.null(pSPR)){
    FpSPR <- rbind(FpSPR, sapply(FpSPR, f.mean))
    rownames(FpSPR) <- c("max","mean")
    Res$FpSPR <- FpSPR
  }

  #---- make summary
  Res$summary <- as.data.frame(Res[substr(names(Res),1,1)=="F"])
  Res$summary <- rbind(Res$summary,Res$summary[1,]/Res$summary[1,1])
  dimnames(Res$summary)[[1]][3] <- "Fref/Fcur"    

  #-----  YPR & SPR figure -----
    F_current <- Res$summary$Fcurrent[1]*Res$summary$Fcurrent[3]
    F.range <- sort(c(F.range,  F_current))
  spr0 <- sum(calc.rel.abund(sel,0,na,M,waa,waa.catch,maa,min.age=min.age,max.age=max.age,Pope=Pope,ssb.coef=ssb.coef)$spr)  
  tmp <- lapply(F.range, function(x) calc.rel.abund(sel,x,na,M,waa,waa.catch,maa,min.age=min.age,max.age=max.age,Pope=Pope,ssb.coef=ssb.coef))
  ypr <- sapply(tmp,function(x) sum(x$ypr))
  spr <- sapply(tmp,function(x) sum(x$spr))/spr0*100

  Res$ypr.spr  <- data.frame(F.range=F.range,ypr=ypr,spr=spr)
  Res$waa <- waa
  Res$waa.catch <- waa.catch  
  Res$maa <- maa
  #------------------------------

  Res$arglist <- arglist
  Res$spr0 <- spr0

  Res$ypr.spr$Frange2Fcurrent  <- Res$ypr.spr$F.range/F_current
  class(Res) <- "ref"
    
  if(isTRUE(plot)){
      plot.Fref(Res)
  }    
  return(Res)
}

plot.Fref <- function(rres,xlabel="max", # or, "mean","Fref/Fcur"
                      vline.text=c("F0.1","Fmax","Fcurrent","Fmed") # and "FpSPR.20.SPR" etc..
                      ){
    old.par <- par()
    par(mar=c(4,4,1,4))
    F.range <- rres$ypr.spr$F.range
    if(xlabel=="Fref/Fcur") F.range <- F.range/rres.pma$summary$Fcurrent[1]*rres.pma$summary$Fcurrent[3]
    if(xlabel=="mean") F.range <- F.range/rres.pma$summary$Fcurrent[1]*rres.pma$summary$Fcurrent[2]    
    spr <- rres$ypr.spr$spr
    ypr <- rres$ypr.spr$ypr
    plot(F.range,spr,xlab=xlabel,ylab="%SPR",type="l",ylim=c(0,max(spr)))
    par(new=T)
    plot(F.range,ypr,axes=F,xlab="",ylab="",lty=2,type="l",ylim=c(0,max(ypr)))
    axis(side=4)
    mtext("YPR",side=4,line=2)
    n.line <- which(rownames(rres$summary) %in% xlabel)
    abline(v=xx <- c(rres$summary[vline.text][n.line,]))
    text(xx,max(ypr)*seq(from=0.5,to=0.3,length=length(vline.text)),vline.text)
    legend("topright",lty=1:2,legend=c("SPR","YPR"))
    options(warn=-1); par(old.par); options(warn=0)
}

calc.rel.abund <- function(sel,Fr,na,M,waa,waa.catch=NULL,maa,min.age=0,max.age=Inf,Pope=TRUE,ssb.coef=0){
    if(is.null(waa.catch)) waa.catch <- waa
    rel.abund <- rep(NA, na)
    rel.abund[1] <- 1
    for (i in 2:(na-1)) {
        rel.abund[i] <- rel.abund[i-1]*exp(-M[i-1]-sel[i-1]*Fr)
    }
    rel.abund[na] <- rel.abund[na-1]*exp(-M[na-1]-sel[na-1]*Fr)*(1-exp(-((max.age-min.age)-(na-2))*(M[na]+sel[na]*Fr)))/(1-exp(-M[na]-sel[na]*Fr))

    if(isTRUE(Pope)){
        ypr1 <- rel.abund*waa.catch[1:na]*(1-exp(-sel[1:na]*Fr))*exp(-M[1:na]/2)
    }
    else{
                                        # use Baranov catch equation
        ypr1 <- rel.abund*(1-exp(-sel[1:na]*Fr-M[1:na]))*sel[1:na]*Fr/
            (sel[1:na]*Fr+M[1:na])*waa.catch[1:na]
    }
    spr <- rel.abund*waa[1:na]*maa[1:na]*exp(-ssb.coef*(sel[1:na]*Fr+M[1:na])) 
  return(list(rel.abund=rel.abund,ypr=ypr1,spr=spr))
}



##----------------------- �����\���֐� ----------------------------
## multi�̃I�v�V�����͊Ǘ����F��multiplier�i�Ǘ��O���selectivity�������j
future.vpa <-
  function(res0,
           currentF=NULL, # �Ǘ��O��F
           multi=1, # �Ǘ���iABC.year����j��F (current F x multi)
           nyear=10,Pope=res0$input$Pope,
           outtype="FULL",
           multi.year=1,#�������̔N����F��ς������ꍇ�B�f�t�H���g��1�B�ς���ꍇ�́A�w�肵���N�܂��̓^�C���X�e�b�v�̗v�f���̃x�N�g���Ŏw��B
           # �N���̎w��
           start.year=NULL, # �����\���̊J�n�N�CNULL�̏ꍇ��VPA�v�Z�̍ŏI�N�̎��̔N
           ABC.year=NULL, # ABC year���v�Z����N�BNULL�̏ꍇ��VPA�v�Z�̍ŏI�N�̎��̎��̔N
           waa.year=NULL, # VPA���ʂ��琶���p�����[�^�������Ă��ĕ��ς������
           # NULL�̏ꍇ�CVPA�̍ŏI�N�̃p�����[�^�������Ă���
           maa.year=NULL, # VPA���ʂ��琶���p�����[�^�������Ă��ĕ��ς������
           M.year=NULL, # VPA���ʂ��琶���p�����[�^�������Ă��ĕ��ς������
           seed=NULL,
           strategy="F", # F: ���l�W�����, E: ���l�������AC: ���l�ʈ��ipre.catch�ŋ��l�ʂ��w��j
           HCR=NULL,# HCR���g���ꍇ�Alist(Blim=154500, Bban=49400,beta=1,year.lag=0)�̂悤�Ɏw�肷�邩�A�ȉ��̈������Z�b�g����,year.lag=0�ŏ����\���N�̗\��SSB���g���B-2�̏ꍇ�͂Q�N�x���SSB���g��
           beta=NULL,delta=NULL,Blim=0,Bban=0,
           plus.group=res0$input$plus.group,
           N=1000,# �m���I�ȃV�~�����[�V����������ꍇ�̌J��Ԃ��񐔁B
           # N+1�̌��ʂ��Ԃ���A1��ڂɌ���_�I�Ȍ��ʂ�                       
           # 0��^����ƌ���_�I�Ȍ��ʂ݂̂��o��
           silent=FALSE, is.plot=TRUE, # �v�Z�������o�́A�v���b�g���邩
           random.select=NULL, # �I�𗦂������_�����T���v�����O����ꍇ�A�����_�����T���v�����O����N������
           # strategy="C"�܂���"E"�̂Ƃ��̂ݗL��
           pre.catch=NULL, # list(year=2012,wcatch=13000), ���l�d�ʂ�given�ŗ^����ꍇ
           # list(year=2012:2017,E=rep(0.5,6)), ���l������given�ŗ^����ꍇ                       
           ##-------- �����Ɋւ���ݒ� -----------------
           rec.new=NULL, # �w�肵���N�̉�����
           # �N���w�肵�Ȃ��ŗ^����ꍇ�́A�����I�ɃX�^�[�g�N�̉����ɂȂ�B
           # list(year=, rec=)�ŗ^����ꍇ�́A�Ή�����N�̉�����u��������B
           ##--- �����֐�
           recfunc=HS.recAR, # �Đ��Y�֌W�̊֐�
           rec.arg=list(a=1,b=1,rho=0,sd=0,bias.correction=TRUE,
                        resample=FALSE,resid=0,resid.year=NULL), # �����̊e��ݒ�
           ##--- Frec�I�v�V�����GFrec�v�Z�̂��߂̐ݒ胊�X�g��^����ƁA�w�肳�ꂽ�ݒ�ł�Frec�ɑΉ�����F�ŏ����\�����s��
           Frec=NULL,
           # list(stochastic=TRUE, # TRUE�̏ꍇ�Astochastic simulation��50%�̊m����Blimit���z��(PMS, TMI)
           # FALSE�̏ꍇ�ARPS�Œ��projection��Bilmit�ƈ�v����(NSK)
           #      future.year=2018, # ���N�̎����ʂ����邩�H
           #      Blimit=450*1000,  # Blimit (x�g��)
           #      scenario="catch.mean" or "blimit" (�f�t�H���g��blimit; "catch.mean"�Ƃ����stochastic simulation�ɂ����镽�ϋ��l�ʂ�Blimit�Ŏw�肵���l�ƈ�v����悤�ɂȂ�)
           #      Frange=c(0.01,2*mult)) # F�̒T���͈�
           waa=NULL,waa.catch=NULL,maa=NULL,M=NULL, # �G�ߖ��̐����p�����[�^�A�܂��́A�����p�����[�^���O����^����ꍇ
           replace.rec.year=2012, # �����ʂ��N�̏����\���ł̉����ʂɒu�������邩�H
           F.sigma=0,
           waa.fun=FALSE, #waa��naa��function�Ƃ��邩
           naa0=NULL,eaa0=NULL,ssb0=NULL,faa0=NULL,
           add.year=0, # �����I�v�V�����ɑΉ��B=1��1�N���]�v�Ɍv�Z����
           det.run=TRUE # 1��߂̃����͌���_�I�����\��������i�����ɂ͑Ή����Ă��Ȃ��j
           ){

    
      argname <- ls()
      arglist <- lapply(argname,function(x) eval(parse(text=x)))
      names(arglist) <- argname
    
      if(is.null(res0$input$unit.waa)) res0$input$unit.waa <- 1
      if(is.null(res0$input$unit.caa)) res0$input$unit.caa <- 1
      if(is.null(res0$input$unit.biom)) res0$input$unit.biom <- 1  
      if(is.null(plus.group)) plus.group <- TRUE
      if(is.null(Pope)) Pope <- FALSE
      
      ##--------------------------------------------------
      if(isTRUE(det.run)) N <- N + 1
      years <- as.numeric(dimnames(res0$naa)[[2]])
    
      ##------------- set default options
      if(is.null(currentF)) currentF <- res0$Fc.at.age
      if(is.null(waa.year)) waa.year <- rev(years)[1]
      if(is.null(maa.year)) maa.year <- rev(years)[1]
      if(is.null(M.year)) M.year <- rev(years)[1]
      if(is.null(start.year)) start.year <- rev(years)[1]+1
      if(is.null(ABC.year)) ABC.year <- rev(years)[1]+1
      ##    if(!is.null(Bban)) Bban$is.Bban <- rep(FALSE,N)        
      arglist$ABC.year <- ABC.year
      ##-------------

      ##---- set S-R functin option -----
      ## �g���֐��ɂ���Ă͕K�v�Ȃ��I�v�V���������邪�A�g��Ȃ��I�v�V���������Ă��G���[�͏o�Ȃ��̂ŁA
                                        # rec.arg$resample��NULL���ǂ����ŁA�p�����g���b�N�Ȍ덷���z�������łȂ����i�c�����T���v�����O�j�𔻕ʂ���
      if(is.null(rec.arg$rho)){
          rec.arg$rho <- 0
          if(!silent) cat("rec.arg$rho is assumed to be 0...\n")
      }
      if(is.null(rec.arg$sd2)) rec.arg$sd2 <- sqrt(rec.arg$sd^2/(1-rec.arg$rho^2)) #rho���ݕ��ϕ␳�pSD # HS.recAR

      ## resampling option���g��Ȃ��ꍇ
      if(is.null(rec.arg$resample)|!isTRUE(rec.arg$resample)){
          if(is.null(rec.arg$bias.correction)) rec.arg$bias.correction <- TRUE # HS.recAR, HS.rec0
          if(is.null(rec.arg$rho)){
              rec.arg$rho <- 0 # HS.recAR, HS.rec0
              rec.arg$resid <- 0
          }
          if(!is.null(rec.arg$rho)){
              if(rec.arg$rho>0){
                  if(is.null(eaa0)){
                      if(is.null(rec.arg$resid.year)) rec.arg$resid <- rep(rev(rec.arg$resid)[1],N)
                      else rec.arg$resid <- rep(mean(rev(rec.arg$resid)[1:rec.arg$resid.year]),N)
                  }
                  else{
                      rec.arg$resid <- eaa0
                  }
              }
              else{
                  rec.arg$resid <- rep(0,N)
              }
          }
      }
      else{
         if(rec.arg$rho>0) stop("You set rho is >0. You cannot use resample=TRUE option when rho>0") # resampling�̏ꍇ�Ɏ��ȑ��ւ͍l���ł��Ȃ��̂�rho�͋����I�Ƀ[��
      }
      
      if(!is.null(rec.arg$sd)) rec.arg$sd <- c(0,rep(rec.arg$sd,N-1))
      if(!is.null(rec.arg$sd2)) rec.arg$sd2 <- c(0,rep(rec.arg$sd2,N-1))
      if(!is.null(HCR) && is.null(HCR$year.lag)) HCR$year.lag <- 0
      ##---------------------------------

      if(!is.null(beta)){
          HCR$beta <- beta
          HCR$Blim <- Blim
          HCR$Bban <- Bban
      }
      
    #  fyears <- seq(from=start.year,to=start.year+nyear-1,by=1/ts)
    fyears <- seq(from=start.year,to=start.year+nyear+add.year,by=1)
    
    fyear.year <- floor(fyears)
    ntime <- length(fyears)
    ages <- as.numeric(dimnames(res0$naa)[[1]]) # ages:VPA�ōl�������ő�N�
    min.age <- min(as.numeric(ages))

    year.overlap <- years %in% start.year   
    {if(sum(year.overlap)==0){
         nage <- sum(!is.na(res0$naa[,ncol(res0$naa)])) # nage:�����\���ōl�����ׂ��N�̐�
     }
     else{
         nage <- sum(!is.na(res0$naa[,year.overlap])) # nage:�����\���ōl�����ׂ��N�̐�
     }}
    
      if(!silent){
          arglist.tmp <-  arglist
          arglist.tmp$res0 <- NULL
          arglist.tmp$Bban <- arglist.tmp$Bblim <- arglist.tmp$beta <- arglist.tmp$ssb0 <- arglist.tmp$strategy <- NULL
#          arglist.tmp <- arglist.tmp[sapply(arglist.tmp,!is.null)]
          print(arglist.tmp)
#          cat("F multiplier= ", multi,"seed=",seed,"\n")
#          cat("ABC year= ", ABC.year,"\n")
#          if(is.null(HCR)) cat("HCR is null")
#          else{
#              cat("HCR= ", HCR$Blimit,"(target)\n")
#              cat("HCR= ", HCR$Bban,"(limit)\n")
#              cat("HCR= ", HCR$beta,"(beta)\n")
#          }
      }
    
    # �V�[�h�̐ݒ�
    if(is.null(seed)) arglist$seed <- as.numeric(Sys.time())
    
    #------------Frec�I�v�V�����̏ꍇ -------------
    if(!is.null(Frec)){
      multi.org <- multi
      if(is.null(Frec$stochastic)) Frec$stochastice <- TRUE
#      if(is.null(Frec$method)) Frec$method <- "optimize"
      if(is.null(Frec$target.probs)) Frec$target.probs <- 50
      if(is.null(Frec$scenario)) Frec$scenario <- "blimit" # 2017/12/25�ǋL 
      if(is.null(Frec$Frange)) Frec$Frange <- c(0.01,multi.org*2)   # 2017/12/25�ǋL(�T������F�͈̔͂̎w��)
      if(is.null(Frec$future.year)) Frec$future.year <- fyears[length(fyears)]-1
      #      arglist$Frec <- Frec
      
      getFrec <- function(x,arglist){
        set.seed(arglist$seed)
        arglist.tmp <- arglist
        arglist.tmp$multi <- x
        arglist.tmp$silent <- TRUE      
        arglist.tmp$Frec <- NULL
        arglist.tmp$is.plot <- FALSE
        if(Frec$stochastic==FALSE){
          arglist.tmp$N <- 0
        }      
        fres.tmp <- do.call(future.vpa,arglist.tmp)
        tmp <- rownames(fres.tmp$vssb)==Frec$future.year
        if(all(tmp==FALSE)) stop("nyear should be longer than Frec$future.year.")
        if(Frec$stochastic==TRUE){
          if(Frec$scenario=="blimit"){          
            is.lower.ssb <- fres.tmp$vssb<Frec$Blimit
            probs <- (sum(is.lower.ssb[tmp,-1],na.rm=T)-1)/
              (length(is.lower.ssb[tmp,-1])-1)*100
            return.obj <- probs-Frec$target.probs
          }
          # stochastic projection�ɂ����镽�ϋ��l�ʂ�ړI�̒l�Ɉ�v������ 
          if(Frec$scenario=="catch.mean"){
            return.obj <- (log(Frec$Blimit)-log(mean(fres.tmp$vwcaa[tmp,-1])))^2
          }
          # stochastic projection�ɂ����镽�ϐe�������ʂ�ړI�̒l�Ɉ�v������ 
          if(Frec$scenario=="ssb.mean"){
            return.obj <- (log(Frec$Blimit)-log(mean(fres.tmp$vssb[tmp,-1])))^2
          }                
        }
        else{
          return.obj <- Frec$Blimit-fres.tmp$vssb[tmp,1]
        }
#        return(ifelse(Frec$method=="nibun",return.obj,return.obj^2))
        return(return.obj^2)                
      }
      
      res <- optimize(getFrec,interval=Frec$Frange,arglist=arglist)        
      multi <- res$minimum
      cat("F multiplier=",multi,"\n")
    }
    
    #-------------- main function ---------------------
    waa.org <- waa
    waa.catch.org <- waa.catch
    maa.org <- maa
    M.org <- M
      
    if(strategy=="C"|strategy=="E") multi.catch <- multi else multi.catch <- 1
    
    faa <- naa <- waa <- waa.catch <- maa <- M <- caa <- 
        array(NA,dim=c(length(ages),ntime,N),dimnames=list(age=ages,year=fyears,nsim=1:N))
    alpha <- array(1,dim=c(ntime,N),dimnames=list(year=fyears,nsim=1:N))
      
    # future biological patameter
    if(!is.null(M.org))  M[] <- M.org  else M[] <- apply(as.matrix(res0$input$dat$M[,years %in% M.year]),1,mean)
    if(!is.null(waa.org))  waa[] <- waa.org  else waa[] <- apply(as.matrix(res0$input$dat$waa[,years %in% waa.year]),1,mean)
    if(!is.null(maa.org))  maa[] <- maa.org  else maa[] <- apply(as.matrix(res0$input$dat$maa[,years %in% maa.year]),1,mean)
    if(!is.null(waa.catch.org))  waa.catch[] <- waa.catch.org
    else{
      if(!is.null(res0$input$dat$waa.catch)) waa.catch[] <- apply(as.matrix(res0$input$dat$waa.catch[,years %in% waa.year]),1,mean)
      else waa.catch <- waa
    }
    
    
    # future F matrix
    faa[] <- currentF*multi # *exp(rnorm(length(faa),0,F.sigma))
    # ABCyear�ȑO��current F���g���B
    faa[,fyears<min(ABC.year),] <- currentF*exp(rnorm(length(faa[,fyears<min(ABC.year),]),0,F.sigma))
    
      ## VPA���ԂƏ����\�����Ԃ�����Ă���ꍇ�AVPA���Ԃ�F��VPA�̌��ʂ��g��
      overlapped.years <- list(future=which(fyear.year %in% years),vpa=which(years %in% fyear.year))
      if(length(overlapped.years$future)>0){  
#          for(jj in 1:length(vpayears.overlapped)){
              for(j in 1:length(overlapped.years$future)){
                  if(any(res0$faa[,overlapped.years$vpa[j]]>0) && !is.null(res0$input$dat$waa[,overlapped.years$vpa[j]])){ # ����faa���[���łȂ��Ȃ�iPMI�̏ꍇ�A2012�܂Ńf�[�^�������Ă��邪�Afaa�̓[���ɂȂ��Ă���̂�
                      faa[,overlapped.years$future[j],] <- res0$faa[,overlapped.years$vpa[j]]
                      waa[,overlapped.years$future[j],] <- res0$input$dat$waa[,overlapped.years$vpa[j]]
                      if(!is.null(res0$input$dat$waa.catch)){
                          waa.catch[,overlapped.years$future[j],] <- res0$input$dat$waa.catch[,overlapped.years$vpa[j]]
                      }
                      else{
                          waa.catch[,overlapped.years$future[j],] <- res0$input$dat$waa[,overlapped.years$vpa[j]]
                      }
                  }
              }}
                                        #}
    
    tmp <- aperm(faa,c(2,1,3))
    tmp <- tmp*multi.year
    faa <- aperm(tmp,c(2,1,3))
    
    #  vpa.multi <- ifelse(is.null(vpa.mode),1,vpa.mode$multi)
    # rps assumption
      rps.mat <- array(NA,dim=c(ntime,N),dimnames=list(fyears,1:N))
      eaa <- matrix(0,ntime,N)
      rec.tmp <- list(rec.resample=NULL,tmparg=NULL)
    
    if (waa.fun){ #�N��ʑ̏d�̗\���֐�
      WAA <- res0$input$dat$waa
      NAA <- res0$naa
#      nage <- nrow(WAA)
      WAA.res <- lapply(1:nage, function(i) {
        log.w <- as.numeric(log(WAA[i,]))
        log.n <- as.numeric(log(NAA[i,]))
        lm(log.w~log.n)
      })
      WAA.cv <- sapply(1:nage, function(i) sqrt(mean(WAA.res[[i]]$residuals^2)))
      WAA.b0 <- sapply(1:nage, function(i) as.numeric(WAA.res[[i]]$coef[1]))
      WAA.b1 <- sapply(1:nage, function(i) as.numeric(WAA.res[[i]]$coef[2]))
      ##      waa.rand <- array(0,dim=c(al,nyear+1-min.age,N))
      set.seed(0)      
      cv.vec <- rep(WAA.cv,N*ntime)
      waa.rand <- array(rnorm(length(cv.vec),-0.5*cv.vec^2,cv.vec),dim=c(nage,ntime,N))
      waa.rand[,,1] <- 0
    }
    
      set.seed(arglist$seed)        

      # 1�N�ڂ̔N��g��������
      if(!start.year%in%years){
          # VPA���ʂ�2011�N�܂ŁA�����\����2012�N�̏ꍇ
          # �����\���̍ŏ��̔N�̐ݒ�G�o���G�[�V�����������₱�����̂ł����Őݒ肳���
          if(start.year==(max(years)+1)){
            {if(is.null(res0$input$dat$M)){
                M.lastyear <- M.org
            }
            else{
                M.lastyear <- res0$input$dat$M[,length(years)]
            }}            
            tmp <- forward.calc.simple(res0$faa[1:nage,length(years)],
                                     res0$naa[1:nage,length(years)],
#                                     res0$input$dat$M[,length(years)],
                                     M.lastyear[1:nage],
                                     plus.group=plus.group)
            naa[1:nage,1,] <- tmp

            # naa0��given�̏ꍇ�A�����ŏ㏑��
            if(!is.null(naa0)){
                naa[,1,] <- naa0
                if(is.null(faa0)) faa0 <- res0$Fc.at.age
                faa[] <- faa0*multi
            }
            
            if(fyears[1]-min.age < start.year){
                thisyear.ssb <- sum(res0$ssb[,as.character(fyears[1]-min.age)],na.rm=T)
                thisyear.ssb <- rep(thisyear.ssb,N)
            }
            else{
                if(waa.fun){
                    waa[2:nage,1,] <- t(sapply(2:nage, function(ii) as.numeric(exp(WAA.b0[ii]+WAA.b1[ii]*log(naa[ii,1,])+waa.rand[ii,1,]))))
                }
                thisyear.ssb <- colSums(naa[,1,]*waa[,1,]*maa[,1,],na.rm=T)*res0$input$unit.waa/res0$input$unit.biom                           }
            
            thisyear.ssb <- thisyear.ssb+(1e-10)
            
            if(!is.null(ssb0)) thisyear.ssb <- colSums(ssb0)
                        
            rec.tmp <- recfunc(thisyear.ssb,res0,
                               rec.resample=rec.tmp$rec.resample,
                               rec.arg=rec.arg)
            eaa[1,] <- rec.tmp$rec.resample[1:N]
            rec.arg$resid <- rec.tmp$rec.resample # AR�I�v�V�����ɑΉ�
            
            if(!is.null(rec.tmp$rec.arg)) rec.arg <- rec.tmp$rec.arg
            naa[1,1,] <- rec.tmp$rec
            if (waa.fun) {
              waa[1,1,] <- as.numeric(exp(WAA.b0[1]+WAA.b1[1]*log(naa[1,1,])+waa.rand[1,1,])) 
            }
            rps.mat[1,] <- naa[1,1,]/thisyear.ssb          
        }
        else{
          stop("ERROR Set appropriate year to start projection\n")
        }
      }
      else{
          naa[,1,] <- res0$naa[,start.year==years]
      }

    
      if(!is.null(rec.new)){
        if(!is.list(rec.new)){
          naa[1,1,] <- rec.new
        }
        else{ # rec.new��list�̏ꍇ
          naa[1,fyears%in%rec.new$year,] <- rec.new$rec
        }}
      
      for(i in 1:(ntime-1)){
       
        #���l�ʂ�given�̏ꍇ
        if(!is.null(pre.catch) && fyears[i]%in%pre.catch$year){
          if(!is.null(pre.catch$wcatch)){
            if(fyears[i]<ABC.year){
              tmpcatch <- as.numeric(pre.catch$wcatch[pre.catch$year==fyears[i]]) 
            }
            else{
              tmpcatch <- as.numeric(pre.catch$wcatch[pre.catch$year==fyears[i]]) * multi.catch                  
            }
          }
          if(!is.null(pre.catch$E)){
            biom <- sum(naa[,i,]*waa[,i,]*res0$input$unit.waa/res0$input$unit.biom)
            if(fyears[i]<ABC.year){
              tmpcatch <- as.numeric(pre.catch$E[pre.catch$year==fyears[i]])  * biom
            }
            else{
              tmpcatch <- as.numeric(pre.catch$E[pre.catch$year==fyears[i]]) * biom * multi.catch                  
            }
          }
          
          # �I�𗦂������_���T���v�����O����ꍇ
#          if(!is.null(random.select)) saa.tmp <- as.numeric(res0$saa[,colnames(res0$saa)==sample(random.select,1)])
          saa.tmp <- sweep(faa[,i,],2,apply(faa[,i,],2,max),FUN="/")
          tmp <- lapply(1:dim(naa)[[3]],
                        function(x) caa.est.mat(naa[,i,x],saa.tmp[,x],
                                                waa.catch[,i,x],M[,i,x],tmpcatch,Pope=Pope))
          faa.new <- sweep(saa.tmp,2,sapply(tmp,function(x) x$x),FUN="*")
          caa[,i,] <- sapply(tmp,function(x) x$caa)
          faa[,i,] <- faa.new
        }
        else{
            faa.new <- NULL
        }
          
          ## HCR���g���ꍇ(���N�̎����ʂ��瓖�N��F��ύX����)
          if(!is.null(HCR) && fyears[i]>=ABC.year
             && is.null(faa.new)) # <- pre.catch�ŋ��l�ʂ��Z�b�g���Ă��Ȃ�
          {
              tmp <- i+HCR$year.lag
              if(tmp>0){
                  ssb.tmp <- colSums(naa[,tmp,]*waa[,tmp,]*maa[,tmp,],na.rm=T)*
                      res0$input$unit.waa/res0$input$unit.biom
              }
              else{
                  vpayear <- fyears[i]+HCR$year.lag
                  ssb.tmp <- sum(res0$ssb[as.character(vpayear)])
              }
              alpha[i,] <- ifelse(ssb.tmp<HCR$Blim,HCR$beta*(ssb.tmp-HCR$Bban)/(HCR$Blim-HCR$Bban),HCR$beta)
              faa[,i,] <- sweep(faa[,i,],2,alpha[i,],FUN="*")
              faa[,i,] <- ifelse(faa[,i,]<0,0,faa[,i,])
          }          
       
          ## ���l���ĂP�N���O�i�i�����͂܂�����Ă��Ȃ��j
          tmp <- forward.calc.mat2(faa[,i,],naa[,i,],M[,i,],plus.group=plus.group)
          # ���ɒl�������Ă���Ƃ���i�P�N�ڂ̉����ʁj�͏����ė��N��NAA������
          naa.tmp <- naa[,i+1,]
          naa.tmp[is.na(naa.tmp)] <- tmp[is.na(naa.tmp)]          
          naa[,i+1, ] <- naa.tmp
        
          ## ���N�̉����̌v�Z
          if(fyears[i+1]-min.age < start.year){
              # �Q�Ƃ���e�������ʂ�VPA���Ԃł���ꍇ�AVPA���Ԃ�SSB���Ƃ��Ă���
              thisyear.ssb <- sum(res0$ssb[,as.character(fyears[i+1]-min.age)],na.rm=T)*res0$input$unit.waa/res0$input$unit.biom
              thisyear.ssb <- rep(thisyear.ssb,N)              
              if(!is.null(ssb0)) thisyear.ssb <- colSums(ssb0)
          }
          else{
              # �����łȂ��ꍇ
            if(waa.fun){
                # ���I��waa�͑Ή�����N��waa��������������Ŏg���H
                waa[2:nage,i+1-min.age,] <- t(sapply(2:nage, function(ii) as.numeric(exp(WAA.b0[ii]+WAA.b1[ii]*log(naa[ii,i+1-min.age,])+waa.rand[ii,i+1-min.age,]))))

            }
            thisyear.ssb <- colSums(naa[,i+1-min.age,]*waa[,i+1-min.age,]*maa[,i+1-min.age,],na.rm=T)*res0$input$unit.waa/res0$input$unit.biom            
          }

          thisyear.ssb <- thisyear.ssb+(1e-10)
          rec.tmp <- recfunc(thisyear.ssb,res0,
                             rec.resample=rec.tmp$rec.resample,
                             rec.arg=rec.arg)
          if(is.na(naa[1,i+1,1]))  naa[1,i+1,] <- rec.tmp$rec          
#          if(!is.null(rec.tmp$rec.arg)) rec.arg <- rec.tmp$rec.arg      
          rps.mat[i+1,] <- naa[1,i+1,]/thisyear.ssb
          eaa[i+1,] <- rec.tmp$rec.resample[1:N]
          rec.arg$resid <- rec.tmp$rec.resample # AR�I�v�V�����ɑΉ�

      }
      
      if (!is.null(rec.arg$rho)) rec.tmp$rec.resample <- NULL

      if(Pope){
          caa[] <- naa*(1-exp(-faa))*exp(-M/2)
      }
      else{
          caa[] <- naa*(1-exp(-faa-M))*faa/(faa+M)
      }      
   
      caa <- caa[,-ntime,,drop=F]
      waa.catch <- waa.catch[,-ntime,,drop=F]
      waa <- waa[,-ntime,,drop=F]
      maa <- maa[,-ntime,,drop=F]                
      naa <- naa[,-ntime,,drop=F]
      faa <- faa[,-ntime,,drop=F]
      alpha <- alpha[-ntime,,drop=F]      
      M <- M[,-ntime,,drop=F]
      fyears <- fyears[-ntime]
    
      biom <- naa*waa*res0$input$unit.waa/res0$input$unit.biom
      ssb <- naa*waa*maa*res0$input$unit.waa/res0$input$unit.biom
    
      wcaa <- caa*waa.catch*res0$input$unit.waa/res0$input$unit.biom
      vwcaa <- apply(wcaa,c(2,3),sum,na.rm=T)
    
      ABC <- apply(as.matrix(vwcaa[fyears%in%ABC.year,,drop=F]),2,sum)

      if(!is.null(rec.arg$resample)) if(rec.arg$resample==TRUE) eaa[] <- NA # resampling����ꍇ�ɂ�eaa�ɂ͂Ȃɂ�����Ȃ�
    
      if(outtype=="FULL"){
          fres <- list(faa=faa,naa=naa,biom=biom,baa=biom,ssb=ssb,wcaa=wcaa,caa=caa,M=M,rps=rps.mat,
                       maa=maa,vbiom=apply(biom,c(2,3),sum,na.rm=T),
                       eaa=eaa,alpha=alpha,
                       waa=waa,waa.catch=waa.catch,currentF=currentF,
                       vssb=apply(ssb,c(2,3),sum,na.rm=T),vwcaa=vwcaa,
                       years=fyears,fyear.year=fyear.year,ABC=ABC,recfunc=recfunc,rec.arg=rec.arg,
                       waa.year=waa.year,maa.year=maa.year,multi=multi,multi.year=multi.year,
                       Frec=Frec,rec.new=rec.new,pre.catch=pre.catch,input=arglist)
    }
      else{
          fres <- list(faa=faa[,,1],M=M[,,1],recruit=naa[1,,],eaa=eaa,baa=biom,
                       maa=maa[,,1],vbiom=apply(biom,c(2,3),sum,na.rm=T),
                       waa=waa[,,1],waa.catch=waa.catch[,,1],currentF=currentF,
                       vssb=apply(ssb,c(2,3),sum,na.rm=T),vwcaa=vwcaa,alpha=alpha,
                       years=fyears,fyear.year=fyear.year,ABC=ABC,recfunc=recfunc,
                       waa.year=waa.year,maa.year=maa.year,multi=multi,multi.year=multi.year,
                       Frec=Frec,rec.new=rec.new,pre.catch=pre.catch,input=arglist)
      }

      ## if(non.det==TRUE){
      ##     fres <- list(faa=faa[,,-1,drop=F],naa=naa[,,-1,drop=F],biom=biom[,,-1,drop=F],
      ##                  ssb=ssb[,,-1,drop=F],wcaa=wcaa[,,-1,drop=F],caa=caa[,,-1,drop=F],
      ##                  M=M[,,-1,drop=F],rps=rps.mat[,-1,drop=F],
      ##                  maa=maa[,,-1,drop=F],vbiom=apply(biom[,,-1,drop=F],c(2,3),sum,na.rm=T),
      ##                  eaa=eaa[,-1,drop=F],
      ##                  waa=waa[,,-1,drop=F],waa.catch=waa.catch[,,-1,drop=F],currentF=currentF,
      ##                  vssb=apply(ssb[,,-1,drop=F],c(2,3),sum,na.rm=T),vwcaa=vwcaa[,-1,drop=F],
      ##                  years=fyears,fyear.year=fyear.year,ABC=ABC,recfunc=recfunc,rec.arg=rec.arg,
      ##                  waa.year=waa.year,maa.year=maa.year,multi=multi,multi.year=multi.year,
      ##                  Frec=Frec,rec.new=rec.new,pre.catch=pre.catch,input=arglist)
      ## }
      
      class(fres) <- "future"
      if(is.plot){
          par(mfrow=c(2,2))
          plot.future(fres)
      }
      if(waa.fun) fres$waa.reg <- WAA.res
      invisible(fres)
  }


forward.calc.mat2 <- function(fav,nav,Mv,plus.group=TRUE){
  nage <- max(which(!is.na(nav[,1])))#length(fav)
  na.age <- which(is.na(nav[-1,1]))
#  naa <- matrix(NA,nage,dim(nav)[[2]])
  naa <- matrix(NA,dim(nav)[[1]],dim(nav)[[2]])  
#  for(a in 2:(nage-1)){
  naa[-c(1,nage,na.age),] <- nav[-c(nage,nage-1,na.age),]*
      exp(-fav[-c(nage,nage-1,na.age),]-Mv[-c(nage,nage-1,na.age),])
#  }
  naa[nage,] <- nav[nage-1,]*exp(-fav[nage-1,]-Mv[nage-1,]) 
  pg <- nav[nage,]*exp(-fav[nage,]-Mv[nage,])
  if(plus.group) naa[nage,] <- naa[nage,] + pg
  return(naa)
}

caa.est.mat <- function(naa,saa,waa,M,catch.obs,Pope){
  saa <- saa/max(saa)
  tmpfunc <- function(logx,catch.obs=catch.obs,naa=naa,saa=saa,waa=waa,M=M,out=FALSE,Pope=Pope){
      x <- exp(logx)
      if(isTRUE(Pope)){
          caa <- naa*(1-exp(-saa*x))*exp(-M/2)
      }
      else{
          caa <- naa*(1-exp(-saa*x-M))*saa*x/(saa*x+M)
      }
      wcaa <- caa*waa
      if(out==FALSE){
          return(log((sum(wcaa,na.rm=T)-catch.obs)^2))
      }
      else{
          return(caa)
      }
  }
  tmp <- optimize(tmpfunc,log(c(0.000001,10)),catch.obs=catch.obs,naa=naa,saa=saa,waa=waa,M=M,Pope=Pope,out=FALSE)#,tol=.Machine$double.eps)
  tmp2 <- tmpfunc(logx=tmp$minimum,catch.obs=catch.obs,naa=naa,saa=saa,waa=waa,M=M,Pope=Pope,out=TRUE)
  return(list(x=exp(tmp$minimum),caa=tmp2))
}

# HS�p; AR�ɂ͑Ή����Ă��Ȃ����A�c�����T���v�����O�ɂ͑Ή����Ă���
HS.rec <- function(ssb,vpares,#deterministic=FALSE,
                   rec.resample=NULL,
                   rec.arg=list(a=1000,b=1000,sd=0.1, # Mesnil�֐���parameter
                                        resample=FALSE,resid=0, # �c�����T���v�����O����ꍇ�Aresample=TRUE�ɂ��āAresid�Ƀ��T���v�����O����c���i�ΐ��j������
                                        bias.correction=TRUE)){

    rec0 <- ifelse(ssb>rec.arg$b,rec.arg$a*rec.arg$b,rec.arg$a*ssb) 
    if(!isTRUE(rec.arg$resample)){
        if(isTRUE(rec.arg$bias.correction)){
            rec <- rec0*exp(rnorm(length(ssb),-0.5*(rec.arg$sd)^2,rec.arg$sd))
        }
        else{
            rec <- rec0*exp(rnorm(length(ssb),0,rec.arg$sd))
        }
    }
    else{
        if(isTRUE(rec.arg$bias.correction)){
            rec <- c(rec0[1],exp(log(rec0[-1])+sample(rec.arg$resid,length(ssb)-1,replace=TRUE))/mean(exp(rec.arg$resid)))
        }
        else{
            rec <- c(rec0[1],exp(log(rec0[-1])+sample(rec.arg$resid,length(ssb)-1,replace=TRUE)))
        }
    }
  return(list(rec=rec,rec.resample=rec.arg$resid)) # �b��I�ύX
}

# RI�p; AR�ɂ͑Ή����Ă��Ȃ����A�c�����T���v�����O�ɂ͑Ή����Ă���
RI.rec <- function(ssb,vpares,#deterministic=FALSE,
                   rec.resample=NULL,
                   rec.arg=list(a=1000,b=1000,sd=0.1, # Mesnil�֐���parameter
                                        resample=FALSE,resid=0, # �c�����T���v�����O����ꍇ�Aresample=TRUE�ɂ��āAresid�Ƀ��T���v�����O����c���i�ΐ��j������
                                        bias.correction=TRUE)){

    rec0 <- rec.arg$a*ssb*exp(-rec.arg$b*ssb) # rec.arg$a*ssb/(1+rec.arg$b*ssb)    
#    rec0 <- ifelse(ssb>rec.arg$b,rec.arg$a*rec.arg$b,rec.arg$a*ssb) 
    if(!isTRUE(rec.arg$resample)){
        if(isTRUE(rec.arg$bias.correction)){
            rec <- rec0*exp(rnorm(length(ssb),-0.5*(rec.arg$sd)^2,rec.arg$sd))
        }
        else{
            rec <- rec0*exp(rnorm(length(ssb),0,rec.arg$sd))
        }
    }
    else{
        if(isTRUE(rec.arg$bias.correction)){
            rec <- c(rec0[1],exp(log(rec0[-1])+sample(rec.arg$resid,length(ssb)-1,replace=TRUE))/mean(exp(rec.arg$resid)))
        }
        else{
            rec <- c(rec0[1],exp(log(rec0[-1])+sample(rec.arg$resid,length(ssb)-1,replace=TRUE)))
        }
    }
  return(list(rec=rec,rec.resample=rec.arg$resid)) # �b��I�ύX
}


# RI�p; AR�ɂ͑Ή����Ă��Ȃ����A�c�����T���v�����O�ɂ͑Ή����Ă���
BH.rec <- function(ssb,vpares,#deterministic=FALSE,
                   rec.resample=NULL,
                   rec.arg=list(a=1000,b=1000,sd=0.1, # Mesnil�֐���parameter
                                        resample=FALSE,resid=0, # �c�����T���v�����O����ꍇ�Aresample=TRUE�ɂ��āAresid�Ƀ��T���v�����O����c���i�ΐ��j������
                                        bias.correction=TRUE)){
    rec0 <- rec.arg$a*ssb/(1+rec.arg$b*ssb)
#    rec0 <- ifelse(ssb>rec.arg$b,rec.arg$a*rec.arg$b,rec.arg$a*ssb) 
    if(!isTRUE(rec.arg$resample)){
        if(isTRUE(rec.arg$bias.correction)){
            rec <- rec0*exp(rnorm(length(ssb),-0.5*(rec.arg$sd)^2,rec.arg$sd))
        }
        else{
            rec <- rec0*exp(rnorm(length(ssb),0,rec.arg$sd))
        }
    }
    else{
        if(isTRUE(rec.arg$bias.correction)){
            rec <- c(rec0[1],exp(log(rec0[-1])+sample(rec.arg$resid,length(ssb)-1,replace=TRUE))/mean(exp(rec.arg$resid)))
        }
        else{
            rec <- c(rec0[1],exp(log(rec0[-1])+sample(rec.arg$resid,length(ssb)-1,replace=TRUE)))
        }
    }
  return(list(rec=rec,rec.resample=rec.arg$resid)) # �b��I�ύX
}


# Hockey-stick(bias.correction�̃I�v�V�����͍폜�B�ǂ�������̂Łj
HS.recAR <- function(ssb,vpares,#deterministic=FALSE,
                      rec.resample=NULL,
                      rec.arg=list(a=1000,b=1000,#gamma=0.01,
                                   sd=0.1, rho=0,
                                   resid=0)#, bias.correction=TRUE)
                      ){
    ## �Đ��Y�֌W����̗\���l
#    rec0 <- rec.arg$a*(ssb+sqrt(rec.arg$b^2+(rec.arg$gamma^2)/4)-sqrt((ssb-rec.arg$b)^2+(rec.arg$gamma^2)/4))
    rec0 <- ifelse(ssb>rec.arg$b,rec.arg$a*rec.arg$b,rec.arg$a*ssb)     
    rec <- rec0*exp(rec.arg$rho*rec.arg$resid) # ���ȑ��֍��݂̗\���l

    rec <- rec*exp(rnorm(length(ssb),-0.5*rec.arg$sd2^2,rec.arg$sd))
    new.resid <- log(rec/rec0)+0.5*rec.arg$sd2^2
    return(list(rec=rec,rec.resample=new.resid))
}


# Beverton-Holt
BH.recAR <- function(ssb,vpares,deterministic=FALSE,rec.resample=NULL,
                   rec.arg=list(a=1000,b=1000,sd=0.1,bias.correction=TRUE)){
  rec0 <- rec.arg$a*ssb/(1+rec.arg$b*ssb)
  rec <- rec0*exp(rec.arg$rho*rec.arg$resid) # ���ȑ��֍��݂̗\���l
  rec <- rec*exp(rnorm(length(ssb),-0.5*rec.arg$sd2^2,rec.arg$sd))
  new.resid <- log(rec/rec0)+0.5*rec.arg$sd2^2
  return(list(rec=rec,rec.resample=new.resid))
}

# Ricker 
RI.recAR <- function(ssb,vpares,deterministic=FALSE,rec.resample=NULL,
                   rec.arg=list(a=1000,b=1000,sd=0.1,bias.correction=TRUE)){                   
    rec0 <- rec.arg$a*ssb*exp(-rec.arg$b*ssb) # rec.arg$a*ssb/(1+rec.arg$b*ssb)
    rec <- rec0*exp(rec.arg$rho*rec.arg$resid) # ���ȑ��֍��݂̗\���l
    rec <- rec*exp(rnorm(length(ssb),-0.5*rec.arg$sd2^2,rec.arg$sd))
    new.resid <- log(rec/rec0)+0.5*rec.arg$sd2^2
    return(list(rec=rec,rec.resample=new.resid))
}


plot.futures <- function(fres.list,conf=c(0.1,0.5,0.9),target="SSB",legend.text="",xlim.tmp=NULL,y.scale=1){
    if(target=="SSB")  aa <- lapply(fres.list,function(x) apply(x$vssb[,-1],1,quantile,probs=conf))
    if(target=="Biomass") aa <- lapply(fres.list,function(x) apply(x$vbiom[,-1],1,quantile,probs=conf))
    if(target=="Catch") aa <- lapply(fres.list,function(x) apply(x$vwcaa[,-1],1,quantile,probs=conf))
    if(target=="Recruit") aa <- lapply(fres.list,function(x) apply(x$naa[1,,-1],1,quantile,probs=conf))    

    if(is.null(xlim.tmp)) xlim.tmp <- as.numeric(range(unlist(sapply(aa,function(x) colnames(x)))))
    plot(0,max(unlist(aa)),type="n",xlim=xlim.tmp,
         ylim=y.scale*c(0,max(unlist(aa))),xlab="Year",ylab=target)
    lapply(1:length(aa),function(i) matpoints(colnames(aa[[i]]),t(aa[[i]]),col=i,type="l",lty=c(2,1,2)))
    legend("bottomright",col=1:length(aa),legend=legend.text,lty=1)
    invisible(aa)
}

plot.future <- function(fres0,ylim.tmp=NULL,xlim.tmp=NULL,vpares=NULL,what=c(TRUE,TRUE,TRUE),conf=0.1,N.line=0,
                        label=c("Biomass","SSB","Catch"),is.legend=TRUE,add=FALSE,col=NULL,...){
    ## �ÖقɁAvssb�Ȃǂ�matrix��1��ڂ͌���_�I�ȃ����̌��ʂƉ��肵�Ă��� 
    if(is.null(col)) col <- 1                        
    matplot2 <- function(x,add=FALSE,...){
        if(add==FALSE) matplot(rownames(x),x,type="l",lty=c(2,1,2),col=col,xlab="Year",...)
        if(add==TRUE) matpoints(rownames(x),x,type="l",lty=c(2,1,2),col=col,xlab="Year",...)    
    }

    if(is.null(xlim.tmp)) xlim.tmp <- range(as.numeric(colnames(fres0$naa)))
    
    if(what[1]){
        matplot2(x <- t(apply(fres0$vbiom[,-1],1,quantile,probs=c(conf,0.5,1-conf))),
                 ylim=c(0,ifelse(is.null(ylim.tmp),max(x),ylim.tmp[1])),
                 xlim=xlim.tmp,
                 ylab=label[1],main=label[1],add=add,...)
        points(rownames(fres0$vbiom),apply(fres0$vbiom[,-1],1,mean),type="b",pch=1)
        points(rownames(fres0$vbiom),as.numeric(fres0$vbiom[,1]),type="b",pch=3)
        if(!is.null(vpares)){
            points(colnames(vpares$baa),colSums(vpares$baa),type="o",pch=20)
        }
        if(N.line>0) matpoints(rownames(fres0$vbiom),fres0$vbiom[,2:(N.line+1)],col="gray",type="l",lty=1)
    }

  if(what[2]){
    matplot2(x <- t(apply(fres0$vssb[,-1],1,quantile,probs=c(conf,0.5,1-conf))),
             ylim=c(0,ifelse(is.null(ylim.tmp),max(x),ylim.tmp[2])),
             xlim=xlim.tmp,           
             ylab=label[2],main=label[2],add=add,...)
    points(rownames(fres0$vssb),apply(fres0$vssb[,-1],1,mean),type="b",pch=1)    
    points(rownames(fres0$vssb),as.numeric(fres0$vssb[,1]),type="b",pch=3)
    if(!is.null(fres0$input$Frec))
        if(!is.null(fres0$input$Frec$scenario))
        if(fres0$input$Frec$scenario!="catch.mean"){
            abline(h=fres0$input$Frec$Blimit,col=2)
            abline(v=fres0$input$Frec$future.year,col=2)            
        }
    if(!is.null(vpares)){
      points(colnames(vpares$ssb),colSums(vpares$ssb),type="o",pch=20)
    }
    if(N.line>0) matpoints(rownames(fres0$vssb),fres0$vssb[,2:(N.line+1)],col="gray",type="l",lty=1)
  }

  if(what[3]){
    matplot2(x <- t(apply(fres0$vwcaa[,-1],1,quantile,probs=c(conf,0.5,1-conf))),
             ylim=c(0,ifelse(is.null(ylim.tmp),max(x),ylim.tmp[3])),
             xlim=xlim.tmp,           
             ylab=label[3],main=label[3],add=add,...)
    points(rownames(fres0$vwcaa),apply(fres0$vwcaa[,-1],1,mean),type="b",pch=1)        
    points(rownames(fres0$vwcaa),as.numeric(fres0$vwcaa[,1]),type="b",pch=3)
    if(!is.null(fres0$input$Frec))
        if(fres0$input$Frec$scenario=="catch.mean"){
        abline(h=fres0$input$Frec$Blimit,col=2)
        abline(v=fres0$input$Frec$future.year,col=2)                    
        }    
    if(!is.null(vpares)){
      points(colnames(vpares$baa),colSums(vpares$input$dat$caa*vpares$input$dat$waa),type="o",pch=20)
    }
    if(N.line>0) matpoints(rownames(fres0$vwcaa),fres0$vwcaa[,2:(N.line+1)],col="gray",type="l",lty=1)    
  }
  if(is.legend){
    if(sum(what)>1) plot(1:10,type = "n",ylab = "", xlab = "", axes = F)
    legend("topleft",lty=c(NA,NA,1,2),legend=c("Deterministic","Mean","Median",paste(100-(conf*2)*100,"%conf")),pch=c(3,1,NA,NA))
  }
  
}

#print.future <- function(fres){ # S3 method ���g��������ł����A�܂����܂����킩��܂���
#  cat(fres$ABC[1])
#}
#

ref.F2 <- function(res0,target.year=c(2018,2023),current.year=2011,Blim,
                   interval=c(0,3),...){
  ssb <- apply(res0$ssb,2,sum)
  Frec <- numeric()
  Frec[1] <- ssb[current.year]/Blim

  for(i in 1:length(target.year)){
    tmpfunc <- function(x,res0,Blim,...){
      fres <- future.vpa(res0=res0,multi=x,...)
      cat(x," ")    
      return((fres$vssb[rownames(fres$vssb)==target.year[i]]-Blim)^2)
    }
    Frec[i+1] <- optimize(tmpfunc,interval=interval,res0=res0,Blim=Blim,...)$minimum
  }
  return(Frec)
}

# 2012. 8. 3 -- �Ǘ���l�v�Z�͊O�ɏo��
getABC <- function(res.vpa, # VPA�̌���
                   res.ref, # �Ǘ���l�v�Z�̌���
                   res.future, # �����\���v�Z�̌���
                   ref.case="all",
                   multi=NULL,
                   N=NULL,                   
                   SSBcur=1000,
                   Blim=1000,Bban=0,                   
                   target.year=NULL, # NULL�̏ꍇ�CABC.year+4
                   catch.year=NULL, # 2013:2017�ȂǁA���l�ʂ̕��ς��o���������ԁANULL�̏ꍇ�AABC.year:ABC.year+4
                   is.plot=TRUE){
  if(all(ref.case=="all")) ref.case <- names(res.ref$summary)
  if(all(is.null(multi))) multi <- rep(1,length(ref.case))
                                       
  nref <- length(ref.case)

  ABC.year <- res.future$input$ABC.year
  if(is.null(target.year)) target.year <- ABC.year+4
  ABC <- wariai <- aveF <- catch5u <- catch5l <- upperSSBlim <- upperSSBcur <- SSBlim <- SSBcur.tmp <- rep(NA,nref)
  names(ABC) <- names(wariai) <- names(aveF) <- paste(ref.case,"x",round(multi,3))
  wcatch <- matrix(NA,5,nref,dimnames=list(((min(ABC.year)):(min(ABC.year)+4)),names(aveF)))

  fres <- list()
  i.tmp <- match(ref.case,names(res.ref$summary))
  
  if(any(is.na(i.tmp)))
    stop(paste("ref.case specification of is wrong!"))

  years <- res.future$year
  currentF <- res.ref$Fcurrent["max"] * res.ref$sel
  N <- ifelse(is.null(N),dim(res.future$naa)[[3]],N)

  for(i in 1:nref){
    tmp <- res.ref$summary[i.tmp[i]][1,1] * res.ref$sel
    tmp <- max(tmp,na.rm=T)/max(currentF,na.rm=T)*multi[i]
    tmpF <- tmp * currentF
    aveF[i] <- mean(tmpF,na.rm=T)
    input.tmp <- res.future$input        
    input.tmp$multi <- tmp
    input.tmp$is.plot <- FALSE
    input.tmp$N <- N

    # Frec�Ŏg��ꂽ�V�[�h�͂Ƃ��Ă����Ȃ��Ƃ����Ȃ�=> seed��Frec�̈����̊O�ɏo�����ƁI
    input.tmp$Frec <- NULL
    
    fres[[i]] <- do.call(future.vpa, input.tmp)
    ABC[i] <- fres[[i]]$ABC[1]
#    browser()    
    if(res.future$input$ts>1){ # ts>2�̏ꍇ�A���l�ʂȂǂ̌v�Z�͗�N���g��
      input.tmp <- res.future$input
      input.tmp$multi <- tmp      
      input.tmp$ts <- 1
      input.tmp$is.plot <- FALSE      
      input.tmp$ABC.year <- ABC.year <- floor(min(input.tmp$ABC.year))
      input.tmp$waa <- input.tmp$maa <- input.tmp$M <- input.tmp$waa.catch <- NULL
      input.tmp$N <- N
      fres[[i]] <- do.call(future.vpa, input.tmp)
      years <- fres[[i]]$year
    }
    wariai[i] <- sum(fres[[i]]$wcaa[,years==ABC.year,1],na.rm=T)/
            sum(fres[[i]]$biom[,years==ABC.year,1],na.rm=T)
    catch.year <- (ABC.year):(ABC.year+4)
    wcatch[,i] <- apply(fres[[i]]$vwcaa[years %in% (catch.year),-1],1,mean,na.rm=T)
    catch5u[i] <- quantile(fres[[i]]$vwcaa[years==max(catch.year),-1],probs=0.9) # catch��2017�N
    catch5l[i] <- quantile(fres[[i]]$vwcaa[years==max(catch.year),-1],probs=0.1) 

    tmp.year <- years %in% target.year
    if(is.null(SSBcur)) SSBcur <- fres[[i]]$vssb[years==(ABC.year),1]    
      
    SSBcur.tmp[i] <- SSBcur
    upperSSBlim[i] <- sum(fres[[i]]$vssb[tmp.year,-1]>Blim)/N*100 # SSB��2018�N�����܂�
    upperSSBcur[i] <- sum(fres[[i]]$vssb[tmp.year,-1]>SSBcur)/N*100
    SSBlim[i] <- Blim
  }

  if(is.plot){
    par(mfrow=c(1,2),mar=c(4,4,2,1))
    vssb <- apply(res.vpa$ssb,2,sum,na.rm=T)/1000
    x <- sapply(fres,function(x) x$vssb[,1])/1000
    plot(range(c(as.numeric(names(vssb)),years)),
         c(0,max(x)*1.1),type="n",xlab="Year",ylab="SSB (x1000)")
    matpoints(years,x,col=1:nref,type="l",lty=1,
            ylim=c(0,max(x)))
    points(as.numeric(names(vssb)),vssb,type="b")
    abline(h=c(SSBlim/1000,SSBcur/1000),col="gray")
    title("SSB in deterministic runs")
    plot(0,axes=F,xlab="",ylab="")
    legend("topleft",col=1:nref,lty=1,legend=names(ABC))
  }
  average <- apply(wcatch,2,mean)
  res.ref$ABC <- rbind(aveF,wariai,catch5l,catch5u,average,
                         upperSSBcur,SSBcur.tmp,upperSSBlim,SSBlim,ABC)
  rownames(res.ref$ABC)[3] <- paste("catch5l during ",min(catch.year),"-",max(catch.year),sep="")
  rownames(res.ref$ABC)[4] <- paste("catch5u during ",min(catch.year),"-",max(catch.year),sep="")  
  rownames(res.ref$ABC)[5] <- paste("average catch during ",min(catch.year),"-",max(catch.year),sep="")    
  rownames(res.ref$ABC)[6] <- paste("upperSSBcur at",target.year)
  rownames(res.ref$ABC)[8] <- paste("upperSSBlim at",target.year)  
  fres0 <- fres
  write.table(round(res.ref$ABC,2),sep="\t")
  save(fres0,file="fres0.R") # �����\���̑S���ʂ�fres0.R�ɂăZ�[�u����Ă���

  # Kobe chart�̍쐬
  kobe.array <- array(NA,dim=c(length(fres),nrow(fres[[1]]$vssb),5))
  dimnames(kobe.array) <- list(names(ABC),rownames(fres[[1]]$vssb),
                               c("catch","Biomass","SSB","upperBlimit","upperBban"))
  for(i in 1:length(fres)){
      kobe.array[i,,] <- as.matrix(get.kobematrix(fres[[i]],
                                   Blim=Blim,Bban=Bban,ssb=TRUE))
  }
  return(list(ABC=res.ref$ABC,kobe.matrix=kobe.array))
}  

#----------------------------------------------------------------------
#----------   �����Ɋւ���֐��B����specific        -------------------
#----------------------------------------------------------------------

#-------------- VPA mode �p�֐� -------------------
caa.est <- function(naa,saa,waa,M,catch.obs,Pope){
  saa <- saa/max(saa)
  tmpfunc <- function(x,catch.obs=catch.obs,naa=naa,saa=saa,waa=waa,M=M,out=FALSE,Pope=Pope){
    if(isTRUE(Pope)){
      caa <- naa*(1-exp(-saa*x))*exp(-M/2)
    }
    else{
      caa <- naa*(1-exp(-saa*x-M))*saa*x/(saa*x+M)
    }
    wcaa <- caa*waa
    if(out==FALSE){
      return((sum(wcaa,na.rm=T)-catch.obs)^2)
    }
    else{
      return(caa)
    }
  }
  tmp <- optimize(tmpfunc,c(0,5),catch.obs=catch.obs,naa=naa,saa=saa,waa=waa,M=M,Pope=Pope,out=FALSE)
  tmp2 <- tmpfunc(x=tmp$minimum,catch.obs=catch.obs,naa=naa,saa=saa,waa=waa,M=M,Pope=Pope,out=TRUE)
  return(list(x=tmp$minimum,caa=tmp2))
}


#---------------- ���ʂ̊m���ߗp�֐� ---------------------
# --------USAGE-------
# tdata <- get.tdata("vpa_results.csv")
# check.res(res.pms,list(fres,fres),tdata,digits=2,type="%")

get.data <- function(tfile){
  tmpdata <- read.csv(tfile,header=F,as.is=F,colClasses="character")
  flags <- which(substr(tmpdata[,1],1,1)=="#")
  tlist <- list()
  for(i in 1:(length(flags)-1)){
      tmp <- tmpdata[(flags[i]+1):(flags[i+1]-1),]
      if(dim(tmp)[[1]]>1){
        dimnames(tmp) <- list(tmp[,1],tmp[1,])
        tmp <- tmp[,!apply(tmp=="",2,all)]
        tlist[[i]] <- sapply((tmp[-1,-1]),as.numeric)
      }
     else{
        tlist[[i]] <- as.numeric(tmp[tmp!=""])
      }
  }
  names(tlist)[1:4] <- c("naa","faa","Biomass","Fc.at.age")
  dimnames(tlist[[3]])[[1]] <- c("SSB","Biomass")
  for(i in 1:tlist[[5]]){
    names(tlist)[(4+(i-1)*4+1):(4+(i*4))] <- c("fnaa","ffaa","fwcaa","ABC")
  }
  return(tlist)
}


### ���ʂ̓��o��
## ���ʂ̏o��
out.vpa <- function(res=NULL, # VPA result 
                    rres=NULL, # reference point 
                    fres=NULL, # future projection result (not nessesarily)
                    ABC=NULL,
                    filename="vpa" # filename without extension
                    ){
  old.par <- par()  
  exit.func <- function(){
#    par(old.par)    
    dev.off()
    options(warn=0)      
  }
  on.exit(exit.func())

  csvname <- paste(filename,".csv",sep="")
  pdfname <- paste(filename,".pdf",sep="")
  pdf(pdfname)
  par(mfrow=c(3,2),mar=c(3,3,2,1))  
  options(warn=-1)
  
  write.table2 <- function(x,title.tmp="",is.plot=TRUE,...){
    if(is.plot){
	    if(!is.null(dim(x))){
    	  matplot(colnames(x),t(x),type="b",ylim=c(0,max(x,na.rm=T)),pch=substr(rownames(x),1,1))
	    }
    	else{
	      barplot(x)
    	}
    title(title.tmp)
    }
    if(!is.null(dim(x))){
      tmp <- matrix("",nrow(x)+1,ncol(x)+1)
      tmp[-1,-1] <- as.character(unlist(x))
      tmp[-1,1] <- rownames(x)
      tmp[1,-1] <- colnames(x)
    }
    else{
      tmp <- x
    }
    write.table(tmp,append=T,sep=",",quote=FALSE,file=csvname,col.names=F,row.names=F,...)
  }

  write(paste("# RVPA outputs at ",date()," & ",getwd()),file=csvname)  
  
  if(!is.null(res)){
    write("# VPA results",file=csvname, append=T)
 
    write("\n# catch at age",file=csvname,append=T)    
    write.table2(res$input$dat$caa,title.tmp="Catch at age")

    write("\n# maturity at age",file=csvname,append=T)    
    write.table2(res$input$dat$maa,title.tmp="Maturity at age")

    write("\n# weight at age for biomass calculation",file=csvname,append=T)    
    write.table2(res$input$dat$waa,title.tmp="Weight at age (for biomass)")

    if(!is.null(res$input$dat$waa.catch)){
    write("\n# weight at age for catch calculation",file=csvname,append=T)    
    write.table2(res$input$dat$waa.catch,title.tmp="Weight at age (for catch)")    
    }
    

    write("\n# M at age",file=csvname,append=T)    
    write.table2(res$input$dat$M,title.tmp="M at age")          

    write("\n# fishing mortality at age",file=csvname,append=T)    
    write.table2(res$faa,title.tmp="F at age")

    write("\n# Current F",file=csvname,append=T)    
    write.table2(res$Fc.at.age,title.tmp="Current F")

    write("\n# numbers at age",file=csvname,append=T)    
    write.table2(res$naa,title.tmp="Numbers at age")

    write("\n# total and spawning biomass ",file=csvname,append=T)
    x <- rbind(colSums(res$ssb),colSums(res$baa),colSums(res$wcaa))
    rownames(x) <- c("Spawning biomass","Total biomass","Catch biomass")
    write.table2(x,title.tmp="Total and spawning biomass")
  }  
  
  if(!is.null(rres)){
    write("\n# Reference points",file=csvname,append=T)
    write.table2(rres$summary,title.tmp="Future F at age",is.plot=F)
  }

  if(!is.null(fres)){
    write("\n# future projection results",file=csvname,append=T)  
    write("\n# future F at age",file=csvname,append=T)
    write.table2(fres$faa[,,1],title.tmp="Future F at age")
    
    write("\n# future numbers at age",file=csvname,append=T)
    write.table2(fres$naa[,,1],title.tmp="Future numbers at age")

    write("\n# future total and spawning biomass",file=csvname,append=T)
    x <- rbind(fres$vssb[,1],fres$vbiom[,1],fres$vwcaa[,1])
    rownames(x) <- c("Spawning biomass","Total biomass","Catch biomass")
    write.table2(x,title.tmp="Future total, spawning and catch biomass")    
  }
  
  if(!is.null(ABC)){
    write("\n# ABC summary",file=csvname,append=T)
    write.table2(ABC$ABC,title.tmp="Future F at age",is.plot=F)
    write("\n# Kobe matrix",file=csvname,append=T)
    for(i in 1:dim(ABC$kobe.matrix)[[3]]){
        write(paste("\n# ",dimnames(ABC$kobe.matrix)[[3]][i]),
              file=csvname,append=T)        
        write.table2(ABC$kobe.matrix[,,i],
                     title.tmp=dimnames(ABC$kobe.matrix)[[3]][i],is.plot=T)        
    }
  }  
}

### 
read.vpa <- function(tfile,
                     caa.label="catch at age",
                     maa.label="maturity at age",
                     waa.label="weight at age",
                     waa.biomass.label="weight at age for biomass calculation",
                     waa.catch.label="weight at age for catch calculation",                     
                     M.label="M at age",
                     faa.label="fishing mortality at age",
                     Fc.label="Current F",
                     naa.label="numbers at age",
                     Blimit=NULL,
                     Pope=NULL, # VPA�v�Z���ɂǂ������g���Ă��邩�����iTRUE or FALSE�j�B�f�t�H���g��NULL��caa,faa,naa�̊֌W���玩�����ʂ��邪�A�������ʂ̌��ʂ�cat�ŏo�͂����̂ŁA������݂Đ��������f����Ă��邩�m�F���Ă��������B
                     fc.year=NULL){

    tmpdata <- read.csv(tfile,header=F,as.is=F,colClasses="character")

    tmpfunc <- function(tmpdata,label,type=NULL){
        flags <- which(substr(tmpdata[,1],1,1)=="#")
        flag.name <- tmpdata[flags,1]
        flag.name <- gsub("#","",flag.name)
        flag.name <- gsub(" ","",flag.name)
        get.flag <- which(flag.name==gsub(" ","",label))
        {if(length(get.flag)>0){
            tdat <- tmpdata[(flags[get.flag]+1):(flags[min(which(flags[get.flag]<flags))]-1),]
            if(!is.null(type)){
                tdat <- tdat[,!apply(tdat=="",2,all)]
                tdat <- as.numeric(tdat)
            }
            else{
                tmp.names <- list(tdat[-1,1],tdat[1,-1])
                tdat <- tdat[,!apply(tdat=="",2,all)]
                tdat <- tdat[!apply(tdat=="",1,all),]
                tdat <- tdat[,!apply(is.na(tdat),2,all)]
                tdat <- tdat[!apply(is.na(tdat),1,all),]
                tdat <- sapply((tdat[-1,-1]),as.numeric)
                tmp.names <- lapply(tmp.names,function(x) x[x!=""])
                tmp.names <- lapply(tmp.names,function(x) x[!is.na(x)])                
                dimnames(tdat) <- tmp.names                
                tdat <- as.data.frame(tdat)
            }
        }
        else{
                tdat <- NULL
            }}
        tdat
    }
  
  dres <- list()
  dres$naa <- tmpfunc(tmpdata,naa.label)
  dres$faa <- tmpfunc(tmpdata,faa.label)
    
  dres$Fc.at.age <- tmpfunc(tmpdata,Fc.label,type="Fc")
    
  dres$input <- list()
  dres$input$dat <- list()
  dres$input$dat$maa <- tmpfunc(tmpdata,maa.label)
  dres$input$dat$caa <- tmpfunc(tmpdata,caa.label)    
  dres$input$dat$M <- tmpfunc(tmpdata,M.label)
  dres$input$dat$waa <- tmpfunc(tmpdata,waa.label)
  if(is.null(dres$input$dat$waa)) dres$input$dat$waa <- tmpfunc(tmpdata,waa.biomass.label)        
  dres$input$dat$waa.catch <- tmpfunc(tmpdata,waa.catch.label)      
  if(is.null(dres$input$dat$waa.catch)) dres$input$dat$waa.catch <- dres$input$dat$waa
    
  dres$ssb <- dres$input$dat$waa * dres$input$dat$maa * dres$naa
  dres$ssb <- as.data.frame(dres$ssb)
  
  dres$baa <- dres$input$dat$waa * dres$naa
  dres$baa <- as.data.frame(dres$baa)
    
  # setting total catch
  dres$wcaa <- dres$input$dat$waa.catch * dres$input$dat$caa
  dres$wcaa <- as.data.frame(dres$wcaa)
    
  dres$Blimit <- Blimit

    ## catch at age�̌v�Z����pope�̋ߎ������g���Ă��邩�ǂ����A�ʏ�͊O������Ƃ��ė^���Ăق����Ƃ��낾���A�^�����Ȃ��ꍇ�A���͂��ꂽcaa,faa,naa�̊֌W�����āAPope�Ōv�Z����Ă���̂������łȂ��̂��𔻒f����dres$input$Pope�ɓ����
  if(is.null(Pope)){
      caa.pope  <- dres$naa*(1-exp(-dres$faa))*exp(-dres$input$dat$M/2)
        diff.pope <- mean(unlist(dres$input$dat$caa/caa.pope))
        
        faa <- dres$faa
        M <- dres$input$dat$M
        caa.bara <- dres$naa*faa/(faa+M)*(1-exp(-faa-M))
        diff.bara <- mean(unlist(dres$input$dat$caa/caa.bara))

        if(abs(1-mean(diff.bara))>abs(1-mean(diff.pope))){
            dres$input$Pope <- TRUE
            cat("Pope is TRUE... OK?\n")
        }
        else{
            dres$input$Pope <- FALSE
            cat("Pope is FALSE... OK?\n")            
        }
  }
  else{
      dres$input$Pope <- Pope
  }    
    if(is.null(dres$Fc.at.age) && !is.null(fc.year)) dres$Fc.at.age <- apply(dres$faa[,colnames(dres$faa)%in%fc.year],1,mean)
    
  return(dres)
}


#type="TorF" # true or false
#type="diff" # excel-RVPA
#type="%" # (excel-RVPA)/excel
check.res <- function(res,fres,tdata,digits=3,type="%"){
    
  check.twomats <- function(mat1,mat2,digits=3,type="%"){
    if(!is.null(colnames(mat1))){
      tmp1 <- mat1[,colnames(mat1)%in%colnames(mat2)]
      tmp2 <- mat2[,colnames(mat2)%in%colnames(mat1)]
    }
    else{
      tmp1 <- mat1
      tmp2 <- mat2
    }
    if(type=="TorF"){
      tmp <- round(tmp1,digits) == round(tmp2,digits)
    }
    if(type=="diff"){
      tmp <- round(tmp1-tmp2,digits)
    }
    if(type=="%"){
      tmp <- round((tmp1-tmp2)/tmp1*100,digits)
    }
    return(tmp)
  }
  
  naa.res <- check.twomats(tdata$naa,res$naa,digits=digits,type=type)
  faa.res <- check.twomats(tdata$faa,res$faa,digits=digits,type=type)
  fcaa.res <- check.twomats(tdata$Fc.at.age,res$Fc.at.age,digits=digits,type=type)
    
  tmp.list <- list(naa=naa.res,faa=faa.res,Fc.at.age=fcaa.res)
  return(tmp.list)       
}


solv.Feq <- function(cvec,nvec,mvec){
  Fres <- rep(0,length(cvec))
 # cat(nvec," ")
  for(i in 1:length(cvec)){
    F0 <- cvec[i]/nvec[i]
    F1 <- cvec[i]*(F0+mvec[i])/nvec[i]/(1-exp(-F0-mvec[i]))
    if(round(cvec[i],6)<round(nvec[i],6)){
      while(abs(F0-F1)>0.0001 ){
        F0 <- F1
        F1 <- cvec[i]*(F0+mvec[i])/nvec[i]/(1-exp(-F0-mvec[i]))
        if(F0-F1==-Inf) cat("\n",cvec[i]," ",nvec[i]," \n")
      }
      Fres[i] <- F1
    }
    else{
      Fres[i] <- 10
      cat("Warning: catch exceeded tot_num at: ",i," ",
          round(cvec[i],6)," ",round(nvec[i],6),"\n")
      }
  }
  Fres
}

forward.calc.simple <- function(fav,nav,Mv,plus.group=TRUE){
    nage <- length(nav)#length(fav)
    naa <- rep(NA,nage)
    naa[c(-1,-nage)] <- nav[c(-nage,-(nage-1))]*exp(-fav[c(-nage,-(nage-1))]-Mv[c(-nage,-(nage-1))])

    naa[nage] <- nav[nage-1]*exp(-fav[nage-1]-Mv[nage-1]) 
    pg <- nav[nage]*exp(-fav[nage]-Mv[nage])
    if(plus.group) naa[nage] <- naa[nage] + pg

    return(naa)
}

forward.calc.mat <- function(fav,nav,Mv,plus.group=TRUE){
  nage <- max(which(!is.na(nav[,1])))#length(fav)
  na.age <- which(is.na(nav[,1]))
#  naa <- matrix(NA,nage,dim(nav)[[2]])
  naa <- matrix(NA,dim(nav)[[1]],dim(nav)[[2]])  
#  for(a in 2:(nage-1)){
    naa[c(-1,-nage,-na.age),] <- nav[c(-nage,-(nage-1),-na.age),]*
        exp(-fav[c(-nage,-(nage-1),-na.age),]-Mv[c(-nage,-(nage-1),-na.age),])
#  }
  naa[nage,] <- nav[nage-1,]*exp(-fav[nage-1,]-Mv[nage-1,]) 
  pg <- nav[nage,]*exp(-fav[nage,]-Mv[nage,])
  if(plus.group) naa[nage,] <- naa[nage,] + pg
  return(naa)
}

get.kobematrix <- function(fres,Blim=0,Bban=0,ssb=TRUE){
    if(isTRUE(ssb))  tmp <- fres$vssb[,-1]
    else  tmp <- fres$vbiom[,-1]
    
    res <- data.frame(
        # ���l��
        catch.deterministic=fres$vwcaa[,1],
        # ������
        biom.deterministic=fres$vbiom[,1],
        # �e����
        ssb.deterministic=fres$vssb[,1],
        # Blim�񕜊m��
        probability.upper.Blim=apply(tmp>Blim,1,mean)*100,
        # Bban�ȏ�m��
        probability.upper.Bban=apply(tmp>Bban,1,mean)*100)

    return(res)
}

############
# RVPA�̌��ʂ���MSY���v�Z����֐�
# ��Ɏg���̂�SR.est(�Đ��Y�֌W���t�B�b�g���AMSY���v�Z)��SR.plot�i�t�B�b�g�������ʂ��v���b�g�j
############

############
# �g����
############
if(0){
                                        # �}�T�o�����m�̃f�[�^��ǂݍ���; modelA��vpa�̋A��l
    modelA <- readRDS("modelA_res.Rdata")
                                        # MSY�v�Z    
    res1 <- SR.est(modelA, 
                   what.est=c(TRUE,TRUE,TRUE), # HS,BH,RI�̂ǂ���t�B�b�g���邩�B
                   bref.year=2013:2015, # �����p�����[�^��p�������
                   years=c(1970:2013), # �ϑ����ꂽSR�֌W��p�������
                   er.log=TRUE, # �덷�BTRUE�őΐ����K�덷
                   fc.year=2013:2015, # MSY�v�Z�̂����ɑI�𗦂𕽋ς������
                   seed=1 # �����̎�B���̒l��ς���Ɨ������ς��̂Ō��ʂ��ς��
                   )
    
    res1$summary # ����p�����[�^�A�Ǘ���l�̊m�F
                                        # �Đ��Y�p�����[�^a,b�̓G�N�Z���Ƃقڈ�v����͂������A�Ǘ���l�͊m���I�V�~�����[�V���������ƂɌv�Z���Ă���̂ŁA�G�N�Z���Ƃ͕K��������v���Ȃ��B�}�T�����炢�̈Ⴂ�͂���݂���

                                        # ���ʂ̃v���b�g(HS�̂�)
    res1.pred <- plot.SR(res1,what.plot=c("hs"))
                                        # ���ʂ̃v���b�g(HS,BH,RI��S��)
    res1.pred <- plot.SR(res1,what.plot=c("hs","bh","ri"))
    allplot(res1) # �v��\�E�O���t�̏o��

}


pred.RI <- function(SSB,a,b) a*SSB*exp(-b*SSB)
pred.BH <- function(SSB,a,b) a*SSB/(1+b*SSB)
pred.HS <- function(SSB,a,b,gamma) a*(SSB+sqrt(b^2+gamma^2/4)-sqrt((SSB-b)^2+gamma^2/4))
pred.SL <- function(SSB,a) a*SSB

##
get.stat <- function(fout,eyear=0,hsp=NULL,tmp.year=NULL){
    col.target <- ifelse(fout$input$N==0,1,-1) 
    tmp <- as.numeric(fout$vssb[(nrow(fout$vssb)-eyear):nrow(fout$vssb),col.target])
    lhs <- sum(tmp<hsp)/length(tmp)
    if(is.null(tmp.year)) tmp.year <- (nrow(fout$vwcaa)-eyear):nrow(fout$vwcaa)
    
    a <- data.frame("catch.mean"=mean(fout$vwcaa[tmp.year,col.target]),
                    "catch.sd"=sd(fout$vwcaa[tmp.year,col.target]),
                    "catch.geomean"=geomean(fout$vwcaa[tmp.year,col.target]),
                    "catch.median"=median(fout$vwcaa[tmp.year,col.target],na.rm=T),
                    "catch.det"=mean(fout$vwcaa[tmp.year,1],na.rm=T),
                    "catch.L10"=quantile(fout$vwcaa[tmp.year,col.target],na.rm=T,probs=0.1),
                    "catch.H10"=quantile(fout$vwcaa[tmp.year,col.target],na.rm=T,probs=0.9),
                    "ssb.mean"=mean(fout$vssb[tmp.year,col.target]),
                    "ssb.sd"=sd(fout$vssb[tmp.year,col.target]),                        
                        "ssb.geomean"=geomean(fout$vssb[tmp.year,col.target]),
                        "ssb.median"=median(fout$vssb[tmp.year,col.target],na.rm=T),
                        "ssb.det"=mean(fout$vssb[tmp.year,1],na.rm=T),
                        "ssb.L10"=quantile(fout$vssb[tmp.year,col.target],na.rm=T,probs=0.1),
                        "ssb.H10"=quantile(fout$vssb[tmp.year,col.target],na.rm=T,probs=0.9),

                        "biom.mean"=mean(fout$vbiom[tmp.year,col.target]),
                        "biom.sd"=sd(fout$vbiom[tmp.year,col.target]),                        
                        "biom.geomean"=geomean(fout$vbiom[tmp.year,col.target]),
                        "biom.median"=median(fout$vbiom[tmp.year,col.target],na.rm=T),
                        "biom.det"=mean(fout$vbiom[tmp.year,1],na.rm=T),
                        "biom.L10"=quantile(fout$vbiom[tmp.year,col.target],na.rm=T,probs=0.1),
                        "biom.H10"=quantile(fout$vbiom[tmp.year,col.target],na.rm=T,probs=0.9),
                        "lower.HSpoint"=lhs,
                        "Fref2Fcurrent"=fout$multi
                        )
        a$U.mean <- a$catch.mean/a$biom.mean
        a$U.median <- a$catch.median/a$biom.median
        a$U.geomean <- a$catch.geomean/a$biom.geomean
        a$U.det <- a$catch.det/a$biom.det

        a$catch.CV <- a$catch.sd/a$catch.mean
        a$ssb.CV <- a$ssb.sd/a$ssb.mean
        a$biom.CV <- a$biom.sd/a$biom.mean

        Faa <- as.data.frame(t(fout$multi * fout$input$res0$Fc.at.age))
        colnames(Faa) <- paste("F",dimnames(fout$naa)[[1]],sep="")
        a <- cbind(a,Faa)
        return(a)
    }

get.stat2 <- function(fout,unit.waa=1,eyear=2,hsp=NULL,tmp.year=NULL){
    col.target <- ifelse(fout$input$N==0,1,-1)     
    if(is.null(tmp.year)) tmp.year <- (nrow(fout$vwcaa)-eyear):nrow(fout$vwcaa)
        nage <- dim(fout$naa)[[1]]
        tb <- fout$naa * fout$waa * unit.waa
        if(is.null(fout$waa.catch)) fout$waa.catch <- fout$waa
        tc <- fout$caa * fout$waa.catch * unit.waa
        ssb <- fout$naa * fout$waa *fout$maa  * unit.waa
        tb.mat <- tc.mat <- ssb.mat <- matrix(0,nage,6)
        for(i in 1:nage){
            tb.mat[i,1] <- mean(tb[i,tmp.year,col.target])
            tb.mat[i,2] <- median(tb[i,tmp.year,col.target])
            tb.mat[i,3] <- geomean(tb[i,tmp.year,col.target])
            tb.mat[i,4] <- mean(tb[i,tmp.year,1])
            tb.mat[i,5:6] <- quantile(tb[i,tmp.year,col.target],probs=c(0.1,0.9),na.rm=T)
            
            tc.mat[i,1] <- mean(tc[i,tmp.year,col.target])
            tc.mat[i,2] <- median(tc[i,tmp.year,col.target])
            tc.mat[i,3] <- geomean(tc[i,tmp.year,col.target])
            tc.mat[i,4] <- mean(tc[i,tmp.year,1])
            tc.mat[i,5:6] <- quantile(tc[i,tmp.year,col.target],probs=c(0.1,0.9),na.rm=T)            

            ssb.mat[i,1] <- mean(ssb[i,tmp.year,col.target])
            ssb.mat[i,2] <- median(ssb[i,tmp.year,col.target])
            ssb.mat[i,3] <- geomean(ssb[i,tmp.year,col.target])
            ssb.mat[i,4] <- mean(ssb[i,tmp.year,1])
            ssb.mat[i,5:6] <- quantile(ssb[i,tmp.year,col.target],probs=c(0.1,0.9),na.rm=T)                        
        }
        tc.mat <- as.numeric(tc.mat)
        tb.mat <- as.numeric(tb.mat)
        ssb.mat <- as.numeric(ssb.mat)        

        # MA; mean, ME; median, GM; geometric mean
        names(tc.mat) <- c(paste("TC-MA-A",1:nage,sep=""),paste("TC-ME-A",1:nage,sep=""),
                           paste("TC-GM-A",1:nage,sep=""),paste("TC-DE-A",1:nage,sep=""),
                           paste("TC-L10-A",1:nage,sep=""),paste("TC-H10-A",1:nage,sep=""))
        names(tb.mat) <- c(paste("TB-MA-A",1:nage,sep=""),paste("TB-ME-A",1:nage,sep=""),
                           paste("TB-GM-A",1:nage,sep=""),paste("TB-DE-A",1:nage,sep=""),
                           paste("TB-L10-A",1:nage,sep=""),paste("TB-H10-A",1:nage,sep=""))
        names(ssb.mat) <- c(paste("SSB-GA-A",1:nage,sep=""),paste("SSB-ME-A",1:nage,sep=""),
                            paste("SSB-GM-A",1:nage,sep=""),paste("SSB-DE-A",1:nage,sep=""),
                            paste("SSB-L10-A",1:nage,sep=""),paste("SSB-H10-A",1:nage,sep=""))        
            
        return(as.data.frame(t(c(tb.mat,tc.mat,ssb.mat))))
    }    


get.stat3 <- function(fout,eyear=0,hsp=NULL,tmp.year=NULL,unit.waa=1){
    col.target <- ifelse(fout$input$N==0,1,-1)
    tmp <- as.numeric(fout$vssb[(nrow(fout$vssb)-eyear):nrow(fout$vssb),col.target])
    lhs <- sum(tmp<hsp)/length(tmp)
    if(is.null(tmp.year)) tmp.year <- (nrow(fout$vwcaa)-eyear):nrow(fout$vwcaa)
    
    a <- data.frame("catch.mean"=mean(fout$vwcaa[tmp.year,col.target]),
                    "catch.sd"=sd(fout$vwcaa[tmp.year,col.target]),
                    "catch.geomean"=geomean(fout$vwcaa[tmp.year,col.target]),
                    "catch.median"=median(fout$vwcaa[tmp.year,col.target],na.rm=T),
                    "catch.det"=mean(fout$vwcaa[tmp.year,1],na.rm=T),
                    "catch.L10"=quantile(fout$vwcaa[tmp.year,col.target],na.rm=T,probs=0.1),
                    "catch.H10"=quantile(fout$vwcaa[tmp.year,col.target],na.rm=T,probs=0.9),
                    "ssb.mean"=mean(fout$vssb[tmp.year,col.target]),
                    "ssb.sd"=sd(fout$vssb[tmp.year,col.target]),                        
                    "ssb.geomean"=geomean(fout$vssb[tmp.year,col.target]),
                    "ssb.median"=median(fout$vssb[tmp.year,col.target],na.rm=T),
                    "ssb.det"=mean(fout$vssb[tmp.year,1],na.rm=T),
                    "ssb.L10"=quantile(fout$vssb[tmp.year,col.target],na.rm=T,probs=0.1),
                    "ssb.H10"=quantile(fout$vssb[tmp.year,col.target],na.rm=T,probs=0.9),

                    "biom.mean"=mean(fout$vbiom[tmp.year,col.target]),
                    "biom.sd"=sd(fout$vbiom[tmp.year,col.target]),                        
                    "biom.geomean"=geomean(fout$vbiom[tmp.year,col.target]),
                    "biom.median"=median(fout$vbiom[tmp.year,col.target],na.rm=T),
                    "biom.det"=mean(fout$vbiom[tmp.year,1],na.rm=T),
                    "biom.L10"=quantile(fout$vbiom[tmp.year,col.target],na.rm=T,probs=0.1),
                    "biom.H10"=quantile(fout$vbiom[tmp.year,col.target],na.rm=T,probs=0.9),
                    "lower.HSpoint"=lhs,
                    "Fref2Fcurrent"=fout$multi
                    )
    a$U.mean <- a$catch.mean/a$biom.mean
    a$U.median <- a$catch.median/a$biom.median
    a$U.geomean <- a$catch.geomean/a$biom.geomean
    a$U.det <- a$catch.det/a$biom.det

    a$catch.CV <- a$catch.sd/a$catch.mean
    a$ssb.CV <- a$ssb.sd/a$ssb.mean
    a$biom.CV <- a$biom.sd/a$biom.mean

    Faa <- as.data.frame(t(fout$multi * fout$input$res0$Fc.at.age))
    colnames(Faa) <- paste("F",dimnames(fout$naa)[[1]],sep="")
    res.stat1 <- cbind(a,Faa) # �����܂ŁAget.stat

    agename <- dimnames(fout$naa)[[1]]
    nage <- dim(fout$naa)[[1]]    
    tb <- fout$naa * fout$waa * unit.waa
    if(is.null(fout$waa.catch)) fout$waa.catch <- fout$waa
    tc <- fout$caa * fout$waa.catch * unit.waa
    ssb <- fout$naa * fout$waa *fout$maa  * unit.waa
    tb.mat <- tc.mat <- ssb.mat <- matrix(0,nage,6)
    for(i in 1:nage){
            tb.mat[i,1] <- mean(tb[i,tmp.year,col.target])
            tb.mat[i,2] <- median(tb[i,tmp.year,col.target])
            tb.mat[i,3] <- geomean(tb[i,tmp.year,col.target])
            tb.mat[i,4] <- mean(tb[i,tmp.year,1])
            tb.mat[i,5:6] <- quantile(tb[i,tmp.year,col.target],probs=c(0.1,0.9),na.rm=T)
            
            tc.mat[i,1] <- mean(tc[i,tmp.year,col.target])
            tc.mat[i,2] <- median(tc[i,tmp.year,col.target])
            tc.mat[i,3] <- geomean(tc[i,tmp.year,col.target])
            tc.mat[i,4] <- mean(tc[i,tmp.year,1])
            tc.mat[i,5:6] <- quantile(tc[i,tmp.year,col.target],probs=c(0.1,0.9),na.rm=T)            

            ssb.mat[i,1] <- mean(ssb[i,tmp.year,col.target])
            ssb.mat[i,2] <- median(ssb[i,tmp.year,col.target])
            ssb.mat[i,3] <- geomean(ssb[i,tmp.year,col.target])
            ssb.mat[i,4] <- mean(ssb[i,tmp.year,1])
            ssb.mat[i,5:6] <- quantile(ssb[i,tmp.year,col.target],probs=c(0.1,0.9),na.rm=T)                        
    }
    tc.mat <- as.numeric(tc.mat)
    tb.mat <- as.numeric(tb.mat)
    ssb.mat <- as.numeric(ssb.mat)        

        # mean, ME; median, geomean; geometric mean
        names(tc.mat) <- c(paste("TC-mean-A",agename,sep=""),paste("TC-median-A",agename,sep=""),
                           paste("TC-geomean-A",agename,sep=""),paste("TC-det-A",agename,sep=""),
                           paste("TC-L10-A",agename,sep=""),paste("TC-H10-A",agename,sep=""))
        names(tb.mat) <- c(paste("TB-mean-A",agename,sep=""),paste("TB-median-A",agename,sep=""),
                           paste("TB-geomean-A",agename,sep=""),paste("TB-det-A",agename,sep=""),
                           paste("TB-L10-A",agename,sep=""),paste("TB-H10-A",agename,sep=""))
        names(ssb.mat) <- c(paste("SSB-GA-A",agename,sep=""),paste("SSB-median-A",agename,sep=""),
                            paste("SSB-geomean-A",agename,sep=""),paste("SSB-det-A",agename,sep=""),
                            paste("SSB-L10-A",agename,sep=""),paste("SSB-H10-A",agename,sep=""))
    res.stat2 <- as.data.frame(t(c(tb.mat,tc.mat,ssb.mat)))
    res.stat <- cbind(res.stat1,res.stat2)
    return(res.stat)    
}    


geomean <- function(x)
{
  ifelse(all(x > 0), exp(mean(log(x))), NA)
}


plot.SR <- function(srres,what.plot=c("hs","bh","ri","sl"),xyscale=c(1.3,1.3),xscale=FALSE,is.legend=TRUE,what.sigma=1,FUN="mean",is.MSYline=TRUE,
                    pick="SSB_MSY"){

    col.tmp <- c(rgb(0.3,0.8,0.3,alpha=0.8),rgb(0.8,0.3,0.3,alpha=0.8),rgb(0.3,0.3,0.8,alpha=0.8))
    
    # xscale=TRUE�̏ꍇ�AB0���Đ��Y�֌W�ɂ���ĈقȂ��Ă���̂ŁA�����̏d�ˏ����͂��Ȃ���S�ƁI
#    tmp <- which(names(srres)==what.plot)
    tmp <- which(names(srres)%in%what.plot)
    resid <- list()

    if(isTRUE(xscale)){
        ssb0 <- srres$summary$B0.ssb.mean1[tmp]
        xrange <- seq(from=0,to=ssb0,length=100)
    }
    else{
        ssb0 <- 1
        xrange <- seq(from=0,to=xyscale[1]*max(srres$dat$SSB,na.rm=T),length=100)
    }

    plot(x <- srres$dat$SSB/ssb0,y <- srres$dat$R,type="l",pch=20,xlim=range(xrange/ssb0),col="gray",
         ylim=c(0,xyscale[2]*max(y,na.rm=T)),xaxs="i",yaxs="i",xlab=ifelse(!xscale,"Spawning biomass (MT)","SB/SB0"),
         ylab="Number of recruits",lwd=1)
    points(x,y,type="p",pch=20,col=gray(c(seq(from=0.7,to=0,length=length(x)))))
    points(rev(x)[1],rev(y)[1],type="p",pch=20,cex=2.5)
    for(i in 1:length(what.plot)){
        Bmsy <- srres$summary[pick][which(what.plot[i]==rownames(srres$summary)),]        
        if(what.plot[i]=="hs"){
            points(xpred <- xrange/ssb0,
                   ypred <- pred.HS(SSB=xrange,
                                       a=srres[what.plot[i]][[1]]$a,b=srres[what.plot[i]][[1]]$b,gamma=srres[what.plot[i]][[1]]$gamma),
                   type="l",lwd=2,col=col.tmp[i],lty=1)
            resid[[i]] <- pred.HS(SSB=x,
                             a=srres[what.plot[i]][[1]]$a,
                             b=srres[what.plot[i]][[1]]$b,
                             gamma=srres[what.plot[i]][[1]]$gamma)
            resid[[i]] <- log(y)-log(resid[[i]])
            Rmsy <- pred.HS(SSB=Bmsy,
                            a=srres[what.plot[i]][[1]]$a,b=srres[what.plot[i]][[1]]$b,gamma=srres[what.plot[i]][[1]]$gamma)
        }
        if(what.plot[i]=="bh"|what.plot[i]=="ri"){
          if(what.plot[i]=="bh") tmpfunc <- pred.BH
          if(what.plot[i]=="ri") tmpfunc <- pred.RI        
          points(xpred <- xrange/ssb0,
                 ypred <- tmpfunc(SSB=xrange,
                                     a=srres[what.plot[i]][[1]]$a,b=srres[what.plot[i]][[1]]$b),type="l",lwd=2,col=col.tmp[i],lty=ifelse(what.plot[i]=="bh",2,3))
          resid[[i]] <- tmpfunc(SSB=x,
                                a=srres[what.plot[i]][[1]]$a,
                                b=srres[what.plot[i]][[1]]$b)
          resid[[i]] <- log(y)-log(resid[[i]])
          Rmsy <- tmpfunc(SSB=Bmsy,
                          a=srres[what.plot[i]][[1]]$a,b=srres[what.plot[i]][[1]]$b)          
        }
        if(what.plot[i]=="sl")
          points(xrange/ssb0,pred.SL(SSB=xrange,
                    a=srres[what.plot[i]][[1]]$a),type="l",lwd=1,col=col.tmp[i])



        if(is.MSYline){ #abline(v=Bmsy/ssb0,col=i+1,lty=2)
            arrows(Bmsy/ssb0,Rmsy*1.2,Bmsy/ssb0,Rmsy,col=col.tmp[i],lty=1,lwd=2,length=.1)
            if(Bmsy/ssb0>rev(xrange)[1]){
                ymax <- xyscale[2]*max(y,na.rm=T)
                arrows(rev(xrange)[2],ifelse(ymax<Rmsy,ymax*0.8,Rmsy*0.8),
                       rev(xrange)[2],ifelse(ymax<Rmsy,ymax,Rmsy),col=col.tmp[i],lty=1,lwd=2,length=.1)
            }
        }
    }

    neg.LL <- sapply(srres[what.plot],function(x) x$res$value)
    k <- sapply(srres[what.plot],function(x) length(x$res$par))
    n <- length(srres$dat$R)
    AICc <- 2*neg.LL+2*k+2*k*(k+1)/(n-k-1)
    if(is.legend){
        legend("topright",legend=paste(toupper(what.plot[order(AICc)]),round(AICc[order(AICc)],2)),
               col=col.tmp[order(AICc)],lwd=1,title="AICc",bg="white",ncol=3)
    }

    return(list(AICc=AICc,resid=resid,x=xpred,y=ypred))
}

# MSY�v�Z�ŉ��肳��Ă���I�𗦂ŋ��l�����Ƃ����{�ɂȂ邩�H => �v�Z���Ԃ��A�A�B
# %SPR�HMSY��B����������F��%SPR���Z
plot.Kobe0 <- function(srres,pickB="",what.plot="hs",plot.history=FALSE){
    tmp <- which(names(srres)==what.plot)-3
    years <- colnames(srres$vpares$ssb)
    y <- srres[what.plot][[1]]$Fhist[[1]]$fmulti/srres[what.plot][[1]]$f.msy
    x <- as.numeric(colSums(srres$vpares$ssb))/
                      srres$summary[pickB][[1]][tmp]
    x <- x[y>0.001]
    years <- years[y>0.001]
    y <- y[y>0.001]    
    plot(x,y,type="n",xlim=c(0,ifelse(max(x)<3,3,max(x,na.rm=T))),
#         ylim=c(0,ifelse(max(y)<3,3,max(y))),
         ylim=c(0,4),
         pch=c(3,rep(1,length(y)-2),20),col=c(1,rep(1,length(y)-2),2),
         cex=c(1,rep(1,length(y)-2),2),ylab="F/Fmsy",xlab="B/Bmsy")
    polygon(c(-1,1,1,-1),c(-1,-1,1,1),col="khaki1",border=NA)
    polygon(c(1,4,4,1),c(-1,-1,1,1),col="olivedrab2",border=NA)
    polygon(c(1,4,4,1),c(1,1,6,6),col="khaki1",border=NA)
    polygon(c(-1,1,1,-1),c(1,1,6,6),col="indianred1",border=NA)
    axis(side=1:2)
    
    points(x,y,type="o",
           pch=c(3,rep(1,length(y)-1),20),
           col=c(1,rep(1,length(y)-1),1),
           cex=c(1,rep(1,length(y)-1),2),ylab="F/Fmsy",xlab="B/Bmsy")
    points(rev(x)[1],rev(y)[1],pch=20)

    if(isTRUE(plot.history)){
      plot(years,y,type="b",ylab="F/Fmsy",ylim=c(0,max(y)))
      abline(h=1)    
      plot(years,x,type="b",xlab="B/Bmsy",ylim=c(0,max(y)))
      abline(h=1)
    }

    invisible(data.frame(years=years,F=y,B=x))    
}

plot.Kobe2 <- get.trend <- function(srres,UBdata=NULL,SR="hs",plot.history=FALSE,is.plot=FALSE,pickU="",pickB="",ylab.tmp="U/Umsy",xlab.tmp="SSB/SSBmsy"){
    
    dres <- srres$vpares
    tmp <- which(names(srres)==SR)-3

    if(is.null(dres$TC.MT)) dres$TC.MT <- as.numeric(colSums(dres$wcaa))

    if(is.null(UBdata)){
    U <- data.frame(years=as.numeric(colnames(dres$baa)),
                    U=as.numeric(dres$TC.MT)/as.numeric(colSums(dres$baa,na.rm=T)))
    B <- data.frame(years=as.numeric(colnames(dres$ssb)),
                    B=as.numeric(colSums(dres$ssb)))
    Catch <- data.frame(years=as.numeric(colnames(dres$baa)),
                    C=as.numeric(dres$TC.MT))
    UBdata <- merge(U,B)
    UBdata <- merge(UBdata,Catch)
    
#    U <- data.frame(years=as.numeric(ts$YEAR),
#                    U=as.numeric(ts$"TC-MT")/as.numeric(ts$"TB-MT"))

#    UBdata$Umsy <- srres$summary$MSY.U.median2[tmp]
#    UBdata$Bmsy <- srres$summary$MSY.ssb.median2[tmp]

    UBdata$Umsy <- srres$summary[pickU][tmp,]
    UBdata$Bmsy <- srres$summary[pickB][tmp,]
    
    UBdata$Uratio <- UBdata$U/UBdata$Umsy
    UBdata$Bratio <- UBdata$B/UBdata$Bmsy
    }

    if(is.plot){
      plot(x <- UBdata$Bratio,
           y <- UBdata$Uratio,type="n",xlim=c(0,ifelse(max(x)<2,2,max(x,na.rm=T))),
           ylim=c(0,ifelse(max(y,na.rm=T)<3,3,max(y,na.rm=T))),
           cex=c(1,rep(1,length(y)-2),3),ylab=ylab.tmp,xlab=xlab.tmp)
      polygon(c(-1,1,1,-1),c(-1,-1,1,1),col="khaki1",border=NA)
      polygon(c(1,6,6,1),c(-1,-1,1,1),col="olivedrab2",border=NA)
      polygon(c(1,6,6,1),c(1,1,6,6),col="khaki1",border=NA)
      polygon(c(-1,0.5,0.5,-1),c(1,1,6,6),col="indianred1",border=NA)
      polygon(c(0.5,1,1,0.5),c(1,1,6,6),col="tan1",border=NA)
      polygon(c(-1,0.5,0.5,-1),c(-1,-1,1,1),col="khaki2",border=NA)
      polygon(c(0.5,1,1,0.5),c(-1,-1,1,1),col="khaki1",border=NA)            
      axis(side=1:2)

#      points(x,y,type="o",pch=c(3,rep(1,length(y)-2),20),col=c(1,rep(1,length(y)-2),1),cex=c(1,rep(1,length(y)-2),1.5))

      points(x,y,type="l",pch=20,col=1,lwd=1)
      points(x,y,type="p",pch=20,col=gray(c(seq(from=0.7,to=0,length=length(x)))),cex=1.2)
      points(rev(x)[1],rev(y)[1],type="p",pch=20,cex=2.5)

    if(isTRUE(plot.history)){
      plot(UBdata$years,y,type="b",ylab="F/Fmsy",ylim=c(0,max(y)))
      abline(h=1)    
      plot(UBdata$years,x,type="b",xlab="B/Bmsy",ylim=c(0,max(y)))
      abline(h=1)
    }}

    invisible(UBdata)    
}


show.likeprof <- function(res){
    x <- tapply(res$hs$surface$obj,list(res$hs$surface$b,res$hs$surface$a),function(x) x)
    image(as.numeric(rownames(x)),as.numeric(colnames(x)),log(x/min(x)),col=rev(heat.colors(12)),ylab="a",xlab="b")
    contour(as.numeric(rownames(x)),as.numeric(colnames(x)),log(x/min(x)),add=T,nlevels=10,zlim=c(0,0.3))
    points(res$hs$b,res$hs$a)
    title("Diagnostics")    
}

# �P�ʂ�catch at age�̔�����100�����Awaa��g�̏ꍇ�A�d�ʂ̒P�ʂ����傤�ǃg���ɂȂ�悤�ɂȂ��Ă���B

plot.info <- function(a,xpos=7){
    plot(1:(nrow(a)+2),type="n",ylab="",xlab="",axes=F)
    units <- ceiling(-1*log10(a[,2]))
    units <- units + 2
    units <- ifelse(units<0,0,units)
    for(i in 1:nrow(a)){
      text(1,nrow(a)-i+2,a[i,1],adj=c(0,1),cex=1)
      text(xpos,nrow(a)-i+2,format(round(a[i,2],units[i]),big.mark=",",
                                   scientific=F),adj=c(1,1))
    }
}

plotfish <- function(image,x,y,size,scale=1,ysize=1){
#    image <- readJPEG("../buri.jpg")
    xx <- dim(image)[1]/dim(image)[2]
    rasterImage(image, 
                x-size*xinch(1), y-size*yinch(1)*xx*ysize, x+size*xinch(1), y+size*yinch(1)*xx*ysize)
}

menplot <- function(x,y,line.col=1,...){
    polygon(c(x,rev(x)),c(y[,1],rev(y[,2])),...)
    if(dim(y)[[2]]>2) points(x,y[,3],type="l",lwd=2,col=line.col)
}

menplot2 <- function(xy,probs=c(0.1,0.9),new=FALSE,xlab=NULL,ylab=NULL,...){
    xx <- rownames(xy)
    yy <- t(apply(xy,1,quantile,probs=c(0.1,0.9)))
    if(isTRUE(new)) matplot(xx,yy,type="n",xlab=xlab,ylab=ylab)
    menplot(xx,yy,...)
}


plotyield <- function(res00,int.res=NULL,detail.plot=FALSE){
#    par(mfrow=c(2,1))
    arg.tmp <- res00$farg
    arg.tmp$rec.arg$sd <- 0
    arg.tmp$N <- 1    
#    fout.tmp <- do.call(future.vpa2,arg.tmp)

    # average
    plot(x <- res00$trace$fmulti,y <- res00$trace$catch.mean,type="n",xlim=c(0,max(x)),
         xlab="Multiplier to current F",ylab="Catch weight",ylim=c(0,max(res00$trace$catch.det,y)))
    menplot(res00$trace$fmulti,cbind(res00$trace$catch.L10,res00$trace$catch.H10),
            col=rgb(210/255,94/255,44/255,0.3),border=NA)    

    ## integrate
    if(!is.null(int.res)){
        points(x,y <- int.res$yield,lty=2,type="o",lwd=1,col="gray")
        points(fmax5 <- x[which.max(y)],y[which.max(y)],pch=20,col="gray")
    }

    points(x <- res00$trace$fmulti,y <- res00$trace$catch.mean,type="l",xlim=c(0,max(x)),
           xlab="Multiplier to current F",ylab="Catch weight",ylim=c(0,max(res00$trace$catch.det,y)))    
    points(fmax1 <- x[which.max(y)],y[which.max(y)],pch=20,col=1)    

    if(isTRUE(detail.plot)){    
    # geomean
        points(x <- res00$trace$fmulti,y <- res00$trace$catch.geomean,col=2,type="l",xlim=c(0,2))
    points(fmax2 <- x[which.max(y)],y[which.max(y)],pch=20,col=2)

    # median
        points(x <- res00$trace$fmulti,y <- res00$trace$catch.median,col=3,type="l",xlim=c(0,2))
        points(fmax3 <- x[which.max(y)],y[which.max(y)],pch=20,col=3)
    }

    # deteministic
    points(x <- res00$trace$fmulti,y <- res00$trace$catch.det,col=4,
           type="l",xlim=c(0,2))
    points(fmax4 <- x[which.max(y)],y[which.max(y)],pch=20,col=4)

    title("Yield vs. F")

    ## plot CV of yield
    par(new=T)
    y <- res00$trace$catch.CV
    plot(x,y,type="l",lwd=3,
         col=rgb(0.8,0.8,0,0.6),axes=F,xlab="",ylab="",
         ylim=c(0,ifelse(max(y,na.rm=T)>1.5,1.5,max(y,na.rm=T))))
    axis(side=4)
    mtext(side=4,"CV of catch",line=2.5,col=rgb(0.8,0.8,0,0.6),cex=0.8)    

    ### plot SSB
    plot(x <- res00$trace$fmulti,y <- res00$trace$ssb.mean,type="n",xlim=c(0,max(x)),
         xlab="Relative F (to current F)",ylab="SSB")
    menplot(res00$trace$fmulti,cbind(res00$trace$ssb.L10,res00$trace$ssb.H10),
            col=rgb(40/255,96/255,163/255,0.3),border=NA)        

    ## integrate
    if(!is.null(int.res)){
        points(x,y <- int.res$ssb,lty=2,type="o",lwd=1,col="gray")
        points(fmax5,y[x==fmax5],pch=20,col="gray")
    }
    
    points(x <- res00$trace$fmulti,y <- res00$trace$ssb.mean,type="l",xlim=c(0,max(x)),
         xlab="Relative F (to current F)",ylab="SSB")
    points(fmax1,y[x==fmax1],pch=20,col=1)

    if(isTRUE(detail.plot)){        
        points(x <- res00$trace$fmulti,y <- res00$trace$ssb.geomean,col=2,type="l",xlim=c(0,2))
        points(fmax2,y[x==fmax2],pch=20,col=2)
    
        points(x <- res00$trace$fmulti,y <- res00$trace$ssb.median,col=3,type="l",xlim=c(0,2))
        points(fmax3,y[x==fmax3],pch=20,col=3)
    }

    points(x <- res00$trace$fmulti,y <- res00$trace$ssb.det,
           col=4,type="l")
    points(fmax4,y[x==fmax4],pch=20,col=4)
    title("SSB vs. F")
    if(!is.null(int.res)){
        legend("topright",lty=c(1,1,1,1,2,NA),col=c(1:4,"gray",NA),legend=c("Simple mean","Geometric mean","Median","Deterministic","Integrate","fill: 80% conf"),bty="n")        
    }
    else{
        if(isTRUE(detail.plot)){
            legend("topright",lty=c(1,1,1,1,NA),col=c(1:4,NA),
                   legend=c("Simple mean","Geometric mean","Median","Deterministic","fill: 80% conf"))
        }
        else{
            legend("topright",lty=c(1,1,NA),col=c(c(1,4),NA),
                   legend=c("Simple mean","Deterministic","fill: 80% conf"))
        }
    }

    #### CV plot
    par(new=T)
    y <- res00$trace$ssb.CV
    plot(x,y,type="l",lwd=3,
         col=rgb(0.8,0.8,0,0.6),axes=F,xlab="",ylab="",
         ylim=c(0,ifelse(max(y,na.rm=T)>1.5,1.5,max(y,na.rm=T))))
    axis(side=4)
    mtext(side=4,"CV of SSB",line=2.5,col=rgb(0.8,0.8,0,0.6),cex=0.8)        
    
#    points(fout.tmp$multi,fout.tmp$vssb[100,1],pch=4)
}

get.SPR <- function(dres,target.SPR=NULL,byear.current=NULL){
    # F�̗��j�I��%SPR�����Ă݂�                                                                             
    # ���N�قȂ�F�␶���p�����[�^�ɑ΂��āAYPR,SPR�ASPR0���ǂ̂��炢�ς���Ă���̂�����(R�R�[�h��2)
    # target.SPR���^������ƁAtarget.SPR�i���j�Ƃ��ė^���������ɑΉ�����SPR�l�ɑ΂���F�̏搔���o�͂���
    #   NULL�̏ꍇ�ɂ�Fc.at.age�ŗ^����ꂽF�ɑ΂���搔�Ƃ���
    #   F=Ftarget.SPR/Fcurrent
    #

    if(is.null(target.SPR)){
        if(is.null(byear.current)) byear.current <- rev(colnames(dres$naa))[1]
        current_spr <- ref.F(dres,waa.year=byear,maa.year=byear,M.year=byear,rps.year=2000:2011,
                             F.range=c(seq(from=0,to=ceiling(max(dres$Fc.at.age,na.rm=T)*2),
                                           length=101),max(dres$Fc.at.age,na.rm=T)),plot=FALSE)$ypr.spr
        target.SPR <- current_spr[current_spr$Frange2Fcurrent==1,]$spr[1]
    }
    
    dres$ysdata <- matrix(0,ncol(dres$faa),5)
    dimnames(dres$ysdata) <- list(colnames(dres$faa),c("perSPR","YPR","SPR","SPR0","F/Ftarget"))
    for(i in 1:ncol(dres$faa)){
	dres$Fc.at.age <- dres$faa[,i] # Fc.at.age�ɑΏ۔N��FAA������
        if(all(dres$Fc.at.age>0)){
            byear <- colnames(dres$faa)[i] # ���N�̐����p�����[�^���g����                                       
            # RVPA��ref.F�֐���YPR�Ȃǂ��v�Z�B                                                                  
            # �z�z���Ă���1.3����1.4�ɃA�b�v�f�[�g���Ă���̂ŁA�V�����ق��̊֐����g������(�Ԃ�l��������ƈႤ)
            a <- ref.F(dres,waa.year=byear,maa.year=byear,M.year=byear,rps.year=2000:2011,
                       pSPR=round(target.SPR),
                       F.range=c(seq(from=0,to=ceiling(max(dres$Fc.at.age,na.rm=T)*2),
                                     length=101),max(dres$Fc.at.age,na.rm=T)),plot=FALSE)
            # YPR��%SPR
            dres$ysdata[i,1:2] <- (as.numeric(rev(a$ypr.spr[which(a$ypr.spr$Frange2Fcurrent==1)[1],2:3])))
            # SPR                                                                                               
            dres$ysdata[i,3] <- a$spr0*dres$ysdata[i,1]/100
            # SPR0                                                                                              
            dres$ysdata[i,4] <- a$spr0
            # relative F
            dres$ysdata[i,5] <- 1/a$summary[3,grep("SPR",colnames(a$summary))][1]
        }
        else{
            break;
            }
    }
    dres$ysdata <- as.data.frame(dres$ysdata)
    return(dres)
}



get.SRdata <- function(vpares,R.dat=NULL,SSB.dat=NULL,years=as.numeric(colnames(vpares$naa))){
    # R.dat��SSB.dat�������^����ꂽ�ꍇ�A������g���ăV���v���Ƀt�B�b�g����
    if(!is.null(R.dat) & !is.null(SSB.dat)){
        dat <- data.frame(R=R.dat,SSB=SSB.dat,year=1:length(R.dat))
    }
    else{
    # �f�[�^�̐��`
        n <- ncol(vpares$naa)
        L <- as.numeric(rownames(vpares$naa)[1])

        dat <- list()
        dat$R <- as.numeric(vpares$naa[1,])
        dat$SSB <- as.numeric(colSums(vpares$ssb,na.rm=TRUE))
        dat$year <- as.numeric(colnames(vpares$ssb))
    # �����N��������炷
        dat$R <- dat$R[(L+1):n]
        dat$SSB <- dat$SSB[1:(n-L)]
        dat$year <- dat$year[(L+1):n]

                                        # �f�[�^�̒��o
        dat <- as.data.frame(dat)
        dat <- dat[dat$year%in%years,]
    }

    class(dat) <- "SRdata"
    return(dat[c("year","SSB","R")])
}

plot.SRdata <- function(SRdata){
    plot(SRdata$SSB,SRdata$R,xlab="SSB",ylab="R",xlim=c(0,max(SRdata$SSB)),ylim=c(0,max(SRdata$R)))
}

est.MSY <- function(vpares,farg,
                   seed=1,
                   nyear=NULL,
                   eyear=0, # �����\���̍Ō��eyear+1�N���𕽍t��ԂƂ���
#                   FUN=median, # ���l�ʂ̉����ő剻���邩�H
                   FUN=mean, # ���l�ʂ̉����ő剻���邩�H                   
                   N=1000, # stochastic�v�Z����Ƃ��̌J��Ԃ���
                   onlylower.pgy=FALSE,# PGY�v�Z����Ƃ������̂݌v�Z����i�v�Z���ԏȗ��̂��߁j
                   optim.method="optimize",
                   max.target="catch.mean", # method="optimize"�ȊO���g���Ƃ��A�ǂ̎w�W���ő剻���邩�B���̃I�v�V�����Ƃ��Ă�"catch.median" (���l�ʂ�median�̍ő剻)
                   calc.yieldcurve=TRUE, # yield curve�𐳊m�Ɍv�Z���邩�ǂ����BTRUE���ƌv�Z���Ԃ��]�v�ɂ�����BFALSE���ƁAyield curve�͐��m�ł͂Ȃ�
                   Blimit=0, 
                   trace.multi=c(seq(from=0,to=0.9,by=0.1),1,seq(from=1.1,to=2,by=0.1),3:5,7,20,100), # Fmsy��T��������AYield curve�������Ƃ��ɃO���b�h�T�[�`������Ƃ���F�̍��݁BFcurrent�ɑ΂���搔�BF���ُ�ɑ傫���ꍇ�A�e��=0�ɂȂ��ĉ�����NA
                   is.plot=TRUE,
                   PGY=NULL, # PGY�Ǘ���l���v�Z���邩�ǂ����B�v�Z���Ȃ��ꍇ��NULL���A�v�Z����ꍇ��c(0.8,0.9,0.95)�̂悤�Ɋ���������
                   B0percent=NULL, # B0_XX%�̊Ǘ���l���v�Z���邩�ǂ���
                   Bempirical=NULL, # ����̐e���ʂ��^�[�Q�b�g�ɂ���ꍇ
                   long.term=20, # ���㎞�Ԃ̉��{�N��̏�Ԃ𕽍t��ԂƉ��肷�邩
                   GT=NULL, # ���㎞�Ԃ��O����^����ꍇ(���㎞�Ԃ̌v�Z�͏����\���Ŏg����N��ʐ��n���E���R���S�W�����g���Ă��邪�A�ʂ̃p�����[�^��^�������ꍇ�ȂǁA�O�Ōv�Z���Ă����ɓ����)
                   mY=5, # ���ȑ��ւ��l�����ĊǗ���l���v�Z����ꍇ�A���t��Ԃ��牽�N�i�߂邩                   
                   resid.year=0, # AR����̏ꍇ�A�ŋߔN���N���̎c���𕽋ς��邩
                   current.resid=NULL # �c���̒l�𒼐ړ����ꍇ�B��̔N�����ݒ肳��Ă��Ă������炪�ݒ肳�ꂽ�炱�̒l���g��
                   ){

    require(tidyverse)

### �����Ŏg�����߂̊֐���`
    ## �ŏ����̂��߂̊֐�
    ## �V�~�����[�V�����񐔂Ԃ�̋��l�ʂ�FUN�imean, geomean, median�j���ő剻����F��I��
    msy.objfun <- function(x,f.arg,FUN=FUN,eyear=eyear){
      f.arg$multi <- x
      fout <- do.call(future.vpa,f.arg)
      return(-FUN(fout$vwcaa[(nrow(fout$vwcaa)-eyear):nrow(fout$vwcaa),-1]))
    }

    trace.func <- function(farg,eyear,hsp=0,trace.N=farg$N,
                           fmulti=c(seq(from=0,to=0.9,by=0.1),1,seq(from=1.1,to=2,by=0.1),3:5,7,20,100)){
        trace.res <- NULL
#        ssb.array <- array(0,dim=c(farg$nyear,farg$N+1,length(fmulti)))
        farg$outtype <- "FULL"
        farg$N <- trace.N
        for(i in 1:length(fmulti)){
            farg$multi <- fmulti[i]
            tmp <- do.call(future.vpa,farg)
#            ssb.array[,,i] <- tmp$vssb
            tmp2 <- get.stat3(tmp,eyear=eyear,hsp=hsp)
            trace.res <- rbind(trace.res,tmp2)
            if(tmp2$"ssb.mean"<trace.res$"ssb.mean"[1]/1000){
                fmulti <- fmulti[1:i]
                break()
            }
          }
        trace.res <- as.data.frame(trace.res)
        trace.res$fmulti <- fmulti
        return(list(table=trace.res))
    }

    which.min2 <- function(x){
        max(which(min(x)==x))
    }

    target.func <- function(fout,faa0=NULL,mY=5,N=2,seed=1,eyear=4,p=1,beta=NULL,delta=NULL,Blim=0,Bban=0,sd0=NULL,current.resid=NULL){
        
        farg <- fout$input
        last.year <- dim(fout$naa)[[2]]

        lag <- as.numeric(dimnames(fout$naa)[[1]])[1]        
        # if(lag==0) SSB.m <- NULL else SSB.m <- fout$ssb[,last.year-lag,]
        SSB.m <- fout$ssb[,last.year-lag,]
        ssb0 <- SSB.m
        
        farg$seed <- seed
        farg$N <- N
        farg$nyear <- mY
        farg$naa0 <- p*fout$naa[,last.year,]
        farg$eaa0 <- fout$eaa[last.year,]+current.resid
        farg$ssb0 <- p*ssb0
        farg$faa0 <- faa0
        farg$beta <- beta
        farg$delta <- delta
        farg$Blim <- Blim
        farg$Bban <- Bban
        farg$start.year <- max(as.numeric(colnames(farg$res0$naa)))+1
        farg$ABC.year <- farg$start.year
        if(!is.null(sd0)) farg$rec.arg$sd <- sd0
        farg$Frec <- NULL
        fout <- do.call(future.vpa,farg)
        out <- get.stat3(fout,eyear=0,hsp=Blimit)
#        out <- cbind(out,get.stat2(fout,eyear=0,hsp=Blimit))
        return(list(out,fout))
    }    

### �֐���`�����
    ## ���㎞�Ԃ��v�Z
    if(is.null(GT)){
        GT <- Generation.Time(vpares,maa.year=farg$maa.year,
                              M.year=farg$M.year)  # Generation Time
    }
    if(is.null(nyear)){
        nyear <- round(GT*long.term)
    }
    trace.N <- N        
    years <- sort(as.numeric(rev(names(vpares$naa))[1:5]))
    nY <- nyear+1    # ����K�v�H�H

    ## �����̒���
    b0 <- numeric() # B0
    fout <- fout0 <- trace <- Fhist <- fout.HS.5par <- list()

    farg.org <- farg.tmp <- farg
    farg.tmp$outtype <- "FULL"
    farg.tmp$nyear <- nyear
    farg.tmp$N <- N
    farg.tmp$silent <- TRUE
    farg.tmp$is.plot <- FALSE
    farg.tmp$ABC.year <- max(years)+1
    farg.tmp$add.year <- 1
    farg.tmp$det.run <- FALSE

    if(!is.null(farg.tmp$pre.catch)){
        farg.tmp$pre.catch <- NULL # pre.catch�I�v�V����������Ƃ��܂������Ȃ��̂łȂ��������Ƃɂ���
        cat("notice: option \"pre.catch\" is turned off in estimating MSY.\n")
    }
    if(!is.null(farg.tmp$rec.new)){
        farg.tmp$rec.new <- NULL # rec.new�v�V����������Ƃ��܂������Ȃ��̂łȂ��������Ƃɂ���
        cat("notice: option \"rec.new\" is turned off in estimating MSY.\n")            
    }

    # B0�̌v�Z
    farg.tmp$multi <- 0
    fout0 <- do.call(future.vpa,farg.tmp)
    B0 <- get.stat3(fout0,eyear=eyear,hsp=Blimit)
#    B0 <- cbind(B0,get.stat2(fout0,eyear=eyear,hsp=Blimit))
    rownames(B0) <- "B0"    
    
    trace <- trace.func(farg.tmp,eyear,hsp=Blimit,fmulti=trace.multi,trace.N=trace.N)

    xx <- which.max(trace$table$catch.mean)+c(-1,1)
    range.tmp <- trace$table$fmulti[xx]
    if(xx[1]==0) range.tmp <- c(0,range.tmp)
    if(is.na(range.tmp[2])) range.tmp[2] <- max(trace$table$fmulti)*10

    farg.tmp$multi <- 1
    cat("Estimating MSY\n")
    if(optim.method=="optimize"){
        tmp <- optimize(msy.objfun,range.tmp,f.arg=farg.tmp,eyear=eyear,FUN=FUN)
        # �ǂɂ������Ă�����葱����
        while(sum(round(tmp$minimum,3)==range.tmp)>0){
            tmp0 <- round(tmp$minimum,3)==range.tmp
            range.tmp <- sort(c(range.tmp[tmp0],
                                range.tmp[tmp0] -2*(mean(range.tmp) - range.tmp[tmp0])))
            range.tmp <- ifelse(range.tmp<0,0,range.tmp)
            tmp <- optimize(msy.objfun,range.tmp,f.arg=farg.tmp,eyear=eyear,FUN=FUN)
        }
        farg.msy <- farg.tmp
        farg.msy$multi <- tmp$minimum # Fc.at.a * multi��Fmsy
        cat("F multiplier=",tmp$minimum,"\n")
        fout.msy <- do.call(future.vpa,farg.msy)
        fout.msy$input$multi <- fout.msy$multi
        if(calc.yieldcurve){
            trace$table <- rbind(trace$table,trace.func(farg.msy,eyear,hsp=Blimit,trace.N=trace.N,
                                                    fmulti=tmp$minimum+c(-0.025,-0.05,-0.075,0,0.025,0.05,0.075))$table)
            trace$table <- trace$table[order(trace$table$fmulti),]
        }
    }
    # optimize�łȂ�grid�ł��ꍇ
    else{
        Fmulti <- seq(from=min(range.tmp),to=max(range.tmp),by=0.01)
        trace.tmp <- trace.func(farg.tmp,eyear,hsp=Blimit,fmulti=Fmulti,trace.N=trace.N)
        farg.msy <- farg.tmp        
        farg.msy$multi <- trace.tmp$table$fmulti[which.max(unlist(trace.tmp$table[max.target]))]
        cat("F multiplier=",farg.msy$multi,"\n")        
        fout.msy <- do.call(future.vpa,farg.msy)
        trace$table <- rbind(trace$table,trace.tmp$table)
        trace$table <- trace$table[order(trace$table$fmulti),]        
    }

    MSY <- get.stat3(fout.msy,eyear=eyear)
#    MSY <- cbind(MSY,get.stat2(fout.msy,eyear=eyear))
    rownames(MSY) <- "MSY"
#    cat(" SSB=",MSY$"ssb.mean","\n")    
    
    ## PGY�̌v�Z
    fout.PGY <- list()
    PGYstat <- NULL
    if(!is.null(PGY)){
        s <- 1
        for(j in 1:length(PGY)){
            cat("Estimating PGY ",PGY[j]*100,"%\n")                        
            ttmp <- trace$table$catch.mean-PGY[j]*MSY$catch.mean
            ttmp <- which(diff(sign(ttmp))!=0)
            frange.list <- list(trace$table$fmulti[ttmp[1]+0:1],
                                trace$table$fmulti[ttmp[2]+0:1])
            if(isTRUE(onlylower.pgy)) i.tmp <- 2  else i.tmp <- 1:2
            for(i in i.tmp){
                farg.pgy <- farg.tmp
                if(sum(is.na(frange.list[[i]]))>0) frange.list[[i]] <- c(0,300)
                farg.pgy$Frec <- list(stochastic=TRUE,
                                      future.year=rev(rownames(fout0$vssb))[1],
                                      Blimit=PGY[j]*MSY$catch.mean,
                                      scenario="catch.mean",Frange=frange.list[[i]])
                fout.PGY[[s]] <- do.call(future.vpa,farg.pgy)
                fout.PGY[[s]]$input$multi <- fout.PGY[[s]]$multi
                PGYstat <- rbind(PGYstat,get.stat3(fout.PGY[[s]]))

                if(calc.yieldcurve){
                    trace$table <- rbind(trace$table,trace.func(farg.msy,eyear,hsp=Blimit,trace.N=trace.N,
                                                                fmulti=fout.PGY[[s]]$multi+c(-0.025,-0.05,-0.075,0,0.025,0.05,0.075))$table)
                    trace$table <- trace$table[order(trace$table$fmulti),]
                }
                s <- s+1                
            }
        }
#        PGYstat <- as.data.frame(t(sapply(fout.PGY,get.stat3,eyear=eyear,hsp=Blimit)))
#        PGYstat <- cbind(PGYstat,as.data.frame(t(sapply(fout.PGY,get.stat2,eyear=eyear,hsp=Blimit))))
        rownames(PGYstat) <- names(fout.PGY) <- paste("PGY",rep(PGY,each=length(i.tmp)),
                                                      rep(c("upper","lower")[i.tmp],length(PGY)),sep="_")
    }
    else{
        PGYstat <-  NULL
        }
    ###

    ## B0_%�̌v�Z
    fout.B0percent <- list()
    B0stat <- NULL
    if(!is.null(B0percent)){
        for(j in 1:length(B0percent)){
            cat("Estimating B0 ",B0percent[j]*100,"%\n")            
            ttmp <- trace$table$ssb.mean-B0percent[j]*B0$ssb.mean
            ttmp <- which(diff(sign(ttmp))!=0)
            frange.list <- trace$table$fmulti[ttmp[1]+0:1]
            farg.b0 <- farg.tmp
            farg.b0$Frec <- list(stochastic=TRUE,
                                 future.year=rev(rownames(fout0$vssb))[1],
                                 Blimit=B0percent[j]*B0$ssb.mean,
                                 scenario="ssb.mean",Frange=frange.list)
            fout.B0percent[[j]] <- do.call(future.vpa,farg.b0)
            fout.B0percent[[j]]$input$multi <- fout.B0percent[[j]]$multi
            B0stat <- rbind(B0stat,get.stat3(fout.B0percent[[j]]))
            if(calc.yieldcurve){
                trace$table <- rbind(trace$table,trace.func(farg.msy,eyear,hsp=Blimit,trace.N=trace.N,
                                                            fmulti=fout.B0percent[[j]]$multi+c(-0.025,-0.05,-0.075,0,0.025,0.05,0.075))$table)
                    trace$table <- trace$table[order(trace$table$fmulti),]
            }                
        }
        rownames(B0stat) <- names(fout.B0percent) <- paste("B0-",B0percent*100,"%",sep="")
    }
    else{
        B0stat <-  NULL
        }
###

    ## �����SSB��ڎw���ꍇ
    fout.Bempirical <- list()
    Bempirical.stat <- NULL
    if(!is.null(Bempirical)){
        for(j in 1:length(Bempirical)){
            cat("Estimating B empirical ",Bempirical[j],"\n")            
            ttmp <- trace$table$ssb.mean-Bempirical[j]
            ttmp <- which(diff(sign(ttmp))!=0)
            frange.list <- trace$table$fmulti[ttmp[1]+0:1]
            farg.ben <- farg.tmp
            farg.ben$Frec <- list(stochastic=TRUE,
                                 future.year=rev(rownames(fout0$vssb))[1],
                                 Blimit=Bempirical[j],
                                 scenario="ssb.mean",Frange=frange.list)
            fout.Bempirical[[j]] <- do.call(future.vpa,farg.ben)
            fout.Bempirical[[j]]$input$multi <- fout.Bempirical[[j]]$multi
            Bempirical.stat <- rbind(Bempirical.stat,get.stat3(fout.Bempirical[[j]]))

            if(calc.yieldcurve){
                trace$table <- rbind(trace$table,trace.func(farg.msy,eyear,hsp=Blimit,trace.N=trace.N,
                                                            fmulti=fout.Bempirical[[j]]$multi+c(-0.025,-0.05,-0.075,0,0.025,0.05,0.075))$table)
                    trace$table <- trace$table[order(trace$table$fmulti),]
            }                            
        }
        rownames(Bempirical.stat) <- names(fout.Bempirical) <- paste("Ben-",round(Bempirical),"",sep="")
    }
    else{
        Bempirical.stat <-  NULL
        }
###

    refvalue <- bind_rows(MSY,B0,PGYstat,B0stat,Bempirical.stat) %>% as_tibble %>%
        mutate(RP_name=c("MSY","B0",rownames(PGYstat),rownames(B0stat),rownames(Bempirical.stat)),
               AR=FALSE)
    refvalue <- refvalue %>%
                   mutate(SSB2SSB0=refvalue$ssb.mean/refvalue$ssb.mean[2])
    sumvalue <- refvalue %>% select(RP_name,AR,ssb.mean,biom.mean,U.mean,catch.mean,Fref2Fcurrent,SSB2SSB0)
    colnames(sumvalue) <- c("RP_name","AR","SSB","B","U","Catch","Fref/Fcur","SSB/SSB0")
    sumvalue <- bind_cols(sumvalue,refvalue[,substr(colnames(refvalue),1,1)=="F"])
    

### AR����̏ꍇ�̊Ǘ���l�̌v�Z�i���t��Ԃ���5�N���i�߂��Ƃ��̒l�j

    if(resid.year > 0 && is.null(current.resid)){
        current.resid <- mean(rev(fout.msy$input$rec.arg$resid)[1:resid.year]) 
        cat("Residuals of ",resid.year," years are averaged as, ",current.resid,"\n")
    }
    else{
        if(resid.year==0){
            current.resid <- 0
        }
    }

    lag <- as.numeric(rownames(fout.msy$naa))[1]            
    eyear <- mY+(lag > 0)*(lag-1)
    
    MSY2 <- target.func(fout.msy,mY=mY,seed=seed,N=N,eyear=mY,current.resid=current.resid)
    B02 <- target.func(fout0,mY=mY,seed=seed,N=N,eyear=mY,current.resid=current.resid)
    if(!is.null(PGY)){
        PGYstat2 <- lapply(1:length(fout.PGY),
                             function(x) target.func(fout.PGY[[x]],mY=mY,seed=seed,N=N,eyear=mY,current.resid=current.resid))
    }
    else{
        PGYstat2 <- NULL
    }

    if(!is.null(B0percent)){
        B0stat2 <- lapply(1:length(fout.B0percent),
                       function(x) target.func(fout.B0percent[[x]],mY=mY,seed=seed,N=N,eyear=mY,current.resid=current.resid)
                       )
    }
    else{
        B0stat2 <- NULL
    }

    if(!is.null(Bempirical)){
        Bempirical.stat2 <- lapply(1:length(fout.Bempirical),
                       function(x) target.func(fout.Bempirical[[x]],mY=mY,seed=seed,N=N,eyear=mY,current.resid=current.resid)
                       )
    }
    else{
        Bempirical.stat2 <- NULL
    }    

    refvalue2 <- bind_rows(MSY2[[1]],B02[[1]],
                       purrr::map_dfr(PGYstat2,function(x) x[[1]]),
                       purrr::map_dfr(B0stat2,function(x) x[[1]]),
                       purrr::map_dfr(Bempirical.stat2,function(x) x[[1]])) %>% as_tibble() %>%
        mutate(RP_name=refvalue$RP_name,AR=TRUE)

    refvalue2 <-  refvalue2 %>%
        mutate(SSB2SSB0=refvalue$ssb.mean/refvalue$ssb.mean[2])
    
    sumvalue2 <- refvalue2 %>% select(RP_name,AR,ssb.mean,biom.mean,U.mean,catch.mean,Fref2Fcurrent,SSB2SSB0)
    colnames(sumvalue2) <- c("RP_name","AR","SSB","B","U","Catch","Fref/Fcur","SSB/SSB0")
    sumvalue2 <- bind_cols(sumvalue2,refvalue2[,substr(colnames(refvalue2),1,1)=="F"])


    ssb.ar.mean <- cbind(apply(MSY2[[2]]$vssb,1,mean),
                         apply(B02[[2]]$vssb,1,mean),
                         sapply(PGYstat2,function(x) apply(x[[2]]$vssb,1,mean)),
                         sapply(B0stat2,function(x) apply(x[[2]]$vssb,1,mean)),
                         sapply(Bempirical.stat2,function(x) apply(x[[2]]$vssb,1,mean)))
    ssb.ar.mean <- sweep(matrix(as.numeric(ssb.ar.mean),nrow(ssb.ar.mean),ncol(ssb.ar.mean)),
              2,unlist(sumvalue$SSB),FUN="/")
    colnames(ssb.ar.mean) <- rownames(sumvalue$SSB)
    
    ### ���ʂ̃v���b�g�Ȃ�

    trace$table <- subset(trace$table,fmulti>0)
    
    if(isTRUE(is.plot)){
        # plot of yield curve
        par(mfrow=c(1,3),mar=c(4,4,2,1))
        plot(trace$table$fmulti,trace$table$"ssb.mean"*1.2,type="n",xlab="Fref/Fcurrent",ylab="SSB")
        abline(v=sumvalue$Fref2Fcurrent,col="gray")
        text(sumvalue$Fref2Fcurrent,max(trace$table$"ssb.mean")*seq(from=1.1,to=0.8,length=nrow(sumvalue)),rownames(sumvalue))
        menplot(trace$table$fmulti,cbind(0,trace$table$"ssb.mean"),col="skyblue",line.col="darkblue")
        title("Equiribrium SSB")
        
        plot(trace$table$fmulti,trace$table$"catch.mean",type="n",xlab="Fref/Fcurrent",ylab="Catch")
        abline(v=sumvalue$Fref2Fcurrent,col="gray")        
        menplot(trace$table$fmulti,cbind(0,trace$table$"catch.mean"),col="lightgreen",line.col="darkgreen")
        title("Equiribrium Catch (Yield curve)")        

        # plot of the effect of AR
        matplot(ssb.ar.mean,type="b",ylab="SSB_MSY_AR/SSB_MSY",xlab="Years from Equiribrium")
        legend("topright",col=1:ncol(ssb.ar.mean),legend=rownames(sumvalue),lty=1:ncol(ssb.ar.mean))
        title("plot of the effect of AR")
    }

    ## kobe II matrix
    #kobe2 <- array(0,dim=c(dim(trace$array)[[1]],dim(trace$array)[[2]],length(sumvalue$SSb)))
    #for(i in 1:length(sumvalue$SSB)){
    #tmp <- trace$array > sumvalue$SSB[i]
    #kobe2[,,i] <- cbind(kobe2,apply(tmp,c(1,2),mean))
    #  }
    #dimnames(kobe2) <- list()

    input.list <- list(B0=fout0$input,
                       msy=fout.msy$input,
                       pgy=lapply(fout.PGY,function(x) x$input),
                       B0percent=lapply(fout.B0percent,function(x) x$input))

    invisible(list(summary=as.data.frame(as.matrix(sumvalue)),
                   summaryAR=as.data.frame(as.matrix(sumvalue2)),
                   summary_tb=bind_rows(sumvalue,sumvalue2),
                   all.stat=as.data.frame(as.matrix(refvalue)),
                   all.statAR=as.data.frame(as.matrix(refvalue2)),
                   all.stat_tb=bind_rows(refvalue,refvalue2),                   
                   trace=trace$table,input.list=input.list,
                   ssb.ar.mean=ssb.ar.mean))    
}


#### function definition
get.perform <- function(fout0,Blimit=0,longyear=50,smallcatch=0.5,N=NULL,
                        shortyear=c(3,5,10),tmp.year=NULL){
    stat1 <- get.stat(fout0,eyear=0,hsp=Blimit,tmp.year=tmp.year)[c("catch.mean","catch.CV","biom.mean","biom.CV","ssb.mean","lower.HSpoint")]
    stat2 <- get.stat2(fout0,eyear=0,tmp.year=tmp.year)
    stat2 <- data.frame(t(as.data.frame(strsplit(colnames(stat2),"-"))),value=as.numeric(stat2))
    rownames(stat2) <- NULL

    # waa�ɂ����d���ϔN��&�g��
    xx <- subset(stat2,X1=="TB" & X2=="MA")
    nage <- sum(!is.na(xx$value))
    tmp <- c(rep(2,ceiling(nage/3)),rep(3,ceiling(nage/3)))
    tmp <- c(rep(1,nage-length(tmp)),tmp)
    if(sum(tmp==1)==0 & sum(tmp==2)>1) tmp[1] <- 1

    xx$bvalue <- xx$value * fout0$waa[,1,1]
    xx$waa <- fout0$waa[,1,1]
    large.portion1 <- tapply(xx$bvalue[!is.na(xx$bvalue)],tmp,sum,na.rm=T)
    stat1$largefish.nature <- large.portion1[names(large.portion1)==3]/sum(large.portion1)
    aage.biom <- sum(xx$bvalue * 0:(length(xx$bvalue)-1))/sum(xx$bvalue)
    
    xx <- subset(stat2,X1=="TC" & X2=="MA")
    xx$bvalue <- xx$value * fout0$waa[,1,1]    
    aage.catch <- sum(xx$bvalue * 0:(length(xx$bvalue)-1))/sum(xx$bvalue)
    large.portion2 <- tapply(xx$bvalue[!is.na(xx$bvalue)],tmp,sum,na.rm=T)
    stat1$largefish.catch <- large.portion2[names(large.portion2)==3]/sum(large.portion2)    

    # ���l��<0.5���ϋ��l�ʂ̕p�x
    if(is.null(tmp.year)) tmp.year <- nrow(fout0$vwcaa)
    stat1$catch.safe <- 1/mean(fout0$vwcaa[tmp.year,]<smallcatch*mean(fout0$vwcaa[tmp.year,]))
    stat1$catch.safe <- ifelse(stat1$catch.safe>longyear,longyear,stat1$catch.safe)
    
    # �e����<Blimit�̕p�x�@���@�m���̋t��
    stat1$ssb.safe <- 1/stat1$"lower.HSpoint"
    stat1$ssb.safe <- ifelse(stat1$ssb.safe>longyear,longyear,stat1$ssb.safe)

    # ABC.year����5�N�ڂ܂ł̕��ϗݐϋ��l��
    short.catch <- numeric()
    for(i in 1:length(shortyear)){
        years <- fout0$input$ABC.year:(fout0$input$ABC.year+shortyear[i])
        short.catch[i] <- mean(apply(fout0$vwcaa[rownames(fout0$vwcaa)%in%years,-1],2,sum))
    }
    names(short.catch) <- paste("short.catch",shortyear,sep="")
    short.catch <- as.data.frame(t(short.catch))

    # ���t��ԂɂȂ����N
    years <- names(fout0$vssb[,1])[-1]
    heikou.diff <- which(diff(fout0$vssb[,1])/fout0$vssb[-1,1]<0.01)
    if(length(heikou.diff)>0) stat1$eq.year <- years[min(heikou.diff)] else stat1$eq.year <- Inf 
    
    dat <- data.frame(stat1,short.catch,aage.biom=aage.biom,aage.catch=aage.catch,effort=fout0$multi,
                      waa=as.data.frame(t(fout0$waa[,1,1])),meigara=as.data.frame(t(tmp)))
    return(dat)
}

plotRadial <- function(index,base=1,col.tmp=NULL,lwd=2,...){
    old.par <- par()
    layout(matrix(c(1,2),2,1),heights=c(2,1))

    index2 <- sweep(matrix(unlist(index),nrow(index),ncol(index)),2,as.numeric(unlist(index[base,])),FUN="/")

    if(is.null(col.tmp)) col.tmp <- brewer.pal(nrow(index2-1),"Set1")
    
    radial.plot(index2,rp.type="p",lwd=lwd,show.grid.labels=FALSE,
                labels=colnames(index),
                radial.lim=c(0,1.5),clockwise=TRUE,start=1,
                line.col=c(NA,col.tmp),
                poly.col=c(rgb(40/255,96/255,163/255,0.2),rep(NA,nrow(index2)-1)), # MSY�����F�œh��
                ...
                )
    refname <- rownames(index)
    par(mar=c(1,0,1,0))
    plot(0,10,type="n",axes=FALSE,ylab="")
    legend("topleft",legend=refname,
           col=c(rgb(40/255,96/255,163/255,0.2),col.tmp),
           ncol=2,lwd=c(10,rep(lwd,length(refname)-1)))
    layout(matrix(c(1),1,1),heights=c(1))
    par(old.par)
    invisible(index2)
}


## �Ǘ���l�����o���֐�
get.Bref <- function(res,SRfunc="hs",B0=c(0.3),SPR0=c(0.3),HS=c(1,1.3),PGY=c("PGY_0.9_upper_hs","PGY_0.9_lower_hs")){
    sumref <- res$summary[rownames(res$summary)==SRfunc,]
    refpoints <- list()
    ## MSY�Ǘ���l���s�b�N�A�b�v
    refpoints$BMSY <- sumref$"SSB_MSY"

    ## B0��̊Ǘ���l��B0�~��
    ## B0�̒l��mout$summary$"B0(SSB)"�ɂ���B�P�Ԗڂ�HS�̌���
    refpoints$B0per <- sumref$"B0(SSB)"[1] * B0 # B0_10,20,30,35,40%�̒l
    names(refpoints$B0per) <- paste(B0*100,"%",sep="")

    ## B_HS�֘A�̊Ǘ���l
    refpoints$BHS <- sumref$b[1] *  HS
    names(refpoints$BHS) <- paste("B_HSx",HS,sep="")

    ## B_PGY�֘A�̊Ǘ���l(HS�����Ƃɂ������̂�PGY.biom.hs�ɂ���܂�)
    x <- res$PGY.biom.hs["ssb.mean"]
    refpoints$BPGY <- x[match(PGY,rownames(x)),1]
    names(refpoints$BPGY) <- PGY

    ## SSB_current
    refpoints$SSBcur <- rev(as.numeric(res$vpares$ssb))[1]

    ## SSB_max
    refpoints$SSBmax <- max(as.numeric(res$vpares$ssb))
    return(unlist(refpoints))
}





plot.RP <- function(rdata,RP=NULL,biomass.scale=1,ymax=1,is.text=TRUE){
    n <- length(rdata)
    rdata <- sort(rdata)
    if(is.null(RP)) RP <- names(rdata)
    ymax <- ymax * seq(from=0.5,to=1,length=n)
    for(j in 1:n){
        abline(v=rdata[j]/biomass.scale,lty=1,lwd=2,col=rgb(40/255,96/255,40/255,0.5))
        if(isTRUE(is.text)){
            text(rdata[j]/biomass.scale,ymax[j],
             paste(RP[j],"=\n",format(round(rdata[j]/biomass.scale),big.mark=","),"",sep=""),adj=0)
        }
    }
}
#### �����ʂ̏�ς݃O���t������
plotBfish <- function(res0, # SR.est�̌���
                      Bref,                      
                      unit.waa=1,ssb.max=Inf,
                      target="hs",biomass.scale=1000,pngfile="fish.png"){

   
    summary <- res0$summary[rownames(res0$summary)==target,]    
    res00 <- res0[names(res0)==target][[1]]
    tres0 <- res00$trace[[1]]
    ssb <- res00$trace[[1]]$ssb.mean/biomass.scale
    
    tmp <- substr(colnames(tres0),1,5)=="TB-MA"
    tb <- tres0[,tmp]/biomass.scale * unit.waa
    tb2 <- sapply(1:ncol(tb),function(x) apply(tb[,1:x,drop=F],1,sum,na.rm=T))
    
    tmp <- substr(colnames(tres0),1,5)=="TC-MA"
    tc <- tres0[,tmp]/biomass.scale * unit.waa
    tc2 <- sapply(1:ncol(tc),function(x) apply(tc[,1:x,drop=F],1,sum,na.rm=T))
    library(png)
    if(file.exists(pngfile)) image <- readPNG(pngfile)
    else image <- NULL

    year.tmp <- rev(colnames(res0$vpares$ssb))[1:5]
    range1 <- range(res0$vpares$ssb)/biomass.scale
    range2 <- range(as.data.frame(res0$vpares$ssb)[as.character(year.tmp)])/biomass.scale

    col.tmp1 <- rgb(40/255,96/255,163/255,seq(from=0.1,to=0.9,length=ncol(tc)))
    col.tmp2 <- rgb(210/255,94/255,44/255,seq(from=0.1,to=0.9,length=ncol(tc)))    
          
    ### plot of SSB
    ssb.max <- min(ssb.max,
                   max(c(range1,summary$"SSB_MSY"),na.rm=T)) *1.5 /biomass.scale
    tb3 <- tb2[which(ssb<ssb.max),]
    matplot(ssb,tb2,type="n",ylab=paste("Biomass (",biomass.scale," MT)",sep=""),xaxs="i",yaxs="i",
            xlab="SSB",
            ylim=c(0,max(tb2[which(ssb<ssb.max),])*1.2),xlim=c(0,ssb.max))
#            ylim=c(0,max(tb2)),xlim=c(0,ssb.max))            
                                        #    menplot(range1,cbind(c(-100,-100),rep(max(tb2)*1.5,2)),col=gray(0.9),border=NA)
                                        #    menplot(range2,cbind(c(-100,-100),rep(max(tb2)*1.5,2)),col=gray(0.7),border=NA)
    # �Ǘ���l�̃v���b�g
    plot.RP(Bref,biomass.scale=biomass.scale,ymax=max(tb3)*1.1)

    # �ߋ��̎��n��
#        matpoints(ssb,tb2[,1],type="l",lwd=2,col="gray",lty=3)
        points(x <- colSums(res0$vpares$ssb)/biomass.scale,
               y <- colSums(res0$vpares$baa)/biomass.scale,type="o",
               col=gray(c(seq(from=0.7,to=0,length=length(x)))),pch=20,cex=1.2,
               lwd=3)
        text(x[1],y[1],colnames(x)[1],adj=0)
        text(rev(x[1]),rev(y)[1],rev(colnames(x))[1],adj=0)

    ## �ςݏグ�O���t
    non.na <- !is.na(ssb)
    for(i in 1:ncol(tb2)) menplot(ssb[non.na], cbind(0,tb2)[non.na,i:(i+1)],col=col.tmp1[i],border=NA)
    title("Total biomass",line=-1,adj=0.1)    
  
                                        #    browser()
        ## abline(v=summary$"SSB_MSY"/biomass.scale,lty=2)
        ## abline(v=summary$"Blimit"/biomass.scale,lty=2)
        ## abline(v=summary$"SSB_HS"/biomass.scale,lty=2)            
        ## text(summary$"SSB_MSY"/biomass.scale,max(tb3)*1.1,
        ##      paste("SSB_MSY=",format(round(summary$"SSB_MSY"/biomass.scale),big.mark=","),"",sep=""),adj=0)
        ## text(summary$"Blimit"/biomass.scale,max(tb3)*1.0,
        ##      paste("SSB_limit=",format(round(summary$"Blimit"/biomass.scale),big.mark=","),
        ##            "",sep=""),adj=0)
        ## text(summary$"SSB_HS"/biomass.scale,max(tb3)*1.05,
        ##      paste("SSB_HS=",format(round(summary$"SSB_HS"/biomass.scale),big.mark=","),
        ##            "",sep=""),adj=0)


        ##  catch
        if(!is.null(res0$vpares$wcaa)) wcatch <- as.numeric(colSums(res0$vpares$wcaa))
        else{
            wcatch <- as.numeric(colSums(res0$vpares$input$dat$caa * res0$vpares$input$dat$waa,na.rm=T))*unit.waa
        }
        matplot(ssb,tc2,type="n",,xaxs="i",yaxs="i",ylab=paste("Catch (",biomass.scale,") MT",sep=""),
                xlab="SSB",
                                        #            ylim=c(0,max(tc2,wcatch)*1.2),xlim=c(0,ssb.max))
                ylim=c(0,max(tc2)*1.2),xlim=c(0,ssb.max))

                                        #    menplot(range1,cbind(c(-100,-100),rep(max(tb2)*1.5,2)),col=gray(0.9),border=NA)
                                        #    menplot(range2,cbind(c(-100,-100),rep(max(tb2)*1.5,2)),col=gray(0.7),border=NA)
    points(x <- as.numeric(colSums(res0$vpares$ssb))/biomass.scale,
           y <- wcatch/biomass.scale,pch=20,lwd=3,
           type="o",col=gray(c(seq(from=0.7,to=0,length=length(x)))))    
    plot.RP(Bref,biomass.scale=biomass.scale,ymax=max(tc2)*1.1,is.text=FALSE)        
#    scale <- max(ssb)/max(tc2) * 0.8
    for(i in 1:ncol(tc2)) menplot(ssb[non.na], cbind(0,tc2)[non.na,i:(i+1)],col=col.tmp2[i],border=NA)

    ## abline(v=summary$"SSB_MSY"/biomass.scale,lty=2)
    ## abline(v=summary$"Blimit"/biomass.scale,lty=2)
    ##     abline(v=summary$"SSB_HS"/biomass.scale,lty=2)                    
    ##     text(x[1],y[1],colnames(res0$vpares$ssb)[1],adj=0)
    ##     text(rev(x)[1],rev(y)[1],rev(colnames(res0$vpares$ssb))[1],adj=0)
#        points(x <- apply(res00$fout[[1]]$vssb,1,mean)[1:10]/biomass.scale,
#               y <- apply(res00$fout[[1]]$vwcaa,1,mean)[1:10]/biomass.scale,col=2,
#               type="o",pch=20,lwd=3)
#        text(rev(x)[1],rev(y)[1],
#             paste("Projection ",rownames(res00$fout[[1]]$vssb)[10],"(F_MSY)",sep=""),adj=-0.1,col=2)

#        points(x <- apply(fout0$vssb,1,mean)[1:10]/biomass.scale,
#               y <- apply(fout0$vwcaa,1,mean)[1:10]/biomass.scale,col="blue",type="o",pch=20,lwd=3)
#        text(rev(x)[1],rev(y)[1],paste("���݂�F�ł�10�N�����\��"),adj=-0.1,col="blue")

        # ���̃v���b�g
        waa.tmp <- (apply(res0$vpares$input$dat$waa,1,mean))^(1/3)*10
        waa.tmp <- waa.tmp/max(waa.tmp) * 0.9
        x <- tc2[which.min(abs(ssb-ssb.max*0.88)),]

        if(!is.null(image)){
            plotfish(image,x=rep(ssb.max*0.88,ncol(tc2)),y=x-diff(c(0,x))/2,
                     size=waa.tmp*0.8,scale=scale,ysize=1)
        }
        text(rep(ssb.max*0.9,ncol(tc2)),x-diff(c(0,x))/2,
             paste(0:(ncol(tc2)-1),"y/o: ",round(apply(res0$vpares$input$dat$waa,1,mean),0)," g"),cex=1)    

    title("Total catch",line=-1,adj=0.1)
    
    ## �w�͗ʂ�CV�̃v���b�g
    tmp <- round(ssb*biomass.scale)>0 & !is.na(ssb)
    matplot(ssb,tres0$fmulti,type="l",ylab="Efforts (Current=1)",col=1,lwd=2,
            xaxs="i",yaxs="i",xlab=paste("SSB (",biomass.scale,"MT)",sep=""),xlim=c(0,ssb.max),
            ylim=c(0,max(tres0$fmulti[tmp]*1.2)))
                                        #    menplot(range1,cbind(c(-100,-100),rep(max(tb2)*1.5,2)),col=gray(0.9),border=NA)
                                        #    menplot(range2,cbind(c(-100,-100),rep(max(tb2)*1.5,2)),col=gray(0.7),border=NA)
#        menplot(ssb[tmp],cbind(0,tres0$fmulti[tmp]),col=rgb(221/255,159/255,33/255,0.5),border=NA)
    plot.RP(Bref,biomass.scale=biomass.scale,ymax=max(tc2)*1.1,is.text=FALSE)            
    title("Efforts",line=-1.5,font=2,adj=0.1)
    par(new=T)
#        y <- res00$trace[[1]]$ssb.CV
        y <- res00$trace[[1]]$catch.CV    
        plot(ssb,y,type="l",lwd=2,col=2,axes=F,xlab="",ylab="",
             ylim=c(0,ifelse(max(y,na.rm=T)>1.5,1.5,max(y,na.rm=T))))    
#        points(ssb,y,type="l",lwd=2,col=3)
        axis(side=4)
        mtext(side=4,"Catch CV",line=3,col=2,cex=0.8)        
    
}

## kobe.matrix�̌v�Z
# Pr(B<Btarget)�݂̂�Ԃ��P���Ȃ��
get.kobemat <- function(fout,N=fout$input$N,nyear=fout$input$nyear,Btarget=0,
                      fmulti=seq(from=0.3,to=1,by=0.1)){
    multi.org <- 1
    fres.short <- list()
    farg <- fout$input
    farg$Frec <- NULL
    farg$N <- N
    farg$nyear <- nyear
    for(i in 1:length(fmulti)){
        farg$multi <- multi.org * fmulti[i]
        fres.short[[i]] <- do.call(future.vpa,farg)
    }
  	prob.btarget <- sapply(fres.short,function(x) apply(x$vssb>Btarget,1,mean))
	colnames(prob.btarget) <- fmulti
    
    invisible(prob.btarget)
}

# Btarget�̓x�N�g���œ��́A���ϐe���ʂȂǂ��o��
get.kobemat2 <- function(fout,N=fout$input$N,nyear=fout$input$nyear,Btarget=0,
                      fmulti=seq(from=0.3,to=1,by=0.1),target.name=1:length(Btarget)){
    multi.org <- 1
    fres.short <- list()
    farg <- fout$input
    farg$Frec <- NULL
    farg$N <- N
    farg$nyear <- nyear
    for(i in 1:length(fmulti)){
        farg$multi <- multi.org * fmulti[i]
        fres.short[[i]] <- do.call(future.vpa,farg)
    }

    # ���ʂ̎��o��
    prob.btarget <- list()
    for(i in 1:length(Btarget)){
		prob.btarget[[i]] <- sapply(fres.short,function(x) apply(x$vssb>Btarget,1,mean))
		colnames(prob.btarget[[i]]) <- fmulti
      }
	names(prob.btarget) <- target.name
	
	# SSB, biomass, catch
    ssb <- sapply(fres.short,function(x) apply(x$vssb,1,mean))
	biom <- sapply(fres.short,function(x) apply(x$vbiom,1,mean))
	catch <- sapply(fres.short,function(x) apply(x$vwcaa, 1,mean))	
	colnames(ssb) <- colnames(biom) <- colnames(catch) <- fmulti
    
    invisible(list(prob.btarget=prob.btarget,ssb=ssb,biom=biom,catch=catch))
}

plot.kobemat <- function(xx,title.name="",line=0){
    yy  <- as.data.frame.table(xx)
    yy$pch <- 20
    yy$color <- "gray"
    yy$color[as.numeric(yy[,3])>0.5] <- "red"
    yy$color[yy[,3]<0.5 & yy[,3]>0.4] <- "pink"
    plot(as.numeric(as.character(yy[,1])),
         as.numeric(as.character(yy[,2])),type="n",col=yy$color,xlab="Years",pch=yy$pch,cex=3,
         ylab="multiplier to F_current")
    abline(h=seq(from=0,to=10,by=0.1),v=2000:2100,col="gray")
    points(as.numeric(as.character(yy[,1])),
         as.numeric(as.character(yy[,2])),col=yy$color,pch=yy$pch,cex=3) 
    title(title.name)
    abline(h=line,col="red")
    text(2+min(as.numeric(as.character(yy[,1]))),line,paste("F_",title.name,sep=""))
    legend("topleft",col=c("gray","pink","red"),legend=c("<40%","40-50%",">50%"),
           title="Pr(B>Btarget)",pch=20,pt.cex=3,bg="white")
}

plot.kobemat2 <- function(yy,...){
	xx <- yy$prob.btarget
    for(i in 1:length(xx)){
		plot.kobemat(xx[[i]],title.name=names(xx)[i],line=-1)
	}
	matplot(yy$ssb,type="l",ylim=c(0,max(yy$ssb)),lty=1)
	title("SSB",line=-1)
	matplot(yy$biom,type="l",ylim=c(0,max(yy$biom)),lty=1)
	title("Biomass",line=-1)	
	matplot(yy$catch,type="l",ylim=c(0,max(yy$catch)),lty=1)		
	title("Catch",line=-1)	
	legend("bottomright",col=1:ncol(yy$ssb),legend=colnames(yy$ssb),lty=1,title="Fcurrentx")
}

####################
### �������M # 2018/06/07

## �����̎c���̎��ȑ��ւ��l�������Đ��Y�֌W�̐���
## L1�m�����i�ŏ���Βl�j������ł��� (sigma��SD)
## TMB = TRUE��marginal likelihood (.cpp�t�@�C�����K�v)

fit.SR <- function(SRdata,SR="HS",method="L2",AR=1,TMB=FALSE,hessian=FALSE,w=rep(1,length(SRdata$year)),length=20){
  
  argname <- ls()
  arglist <- lapply(argname,function(xx) eval(parse(text=xx)))
  names(arglist) <- argname
  
  rec <- SRdata$R
  ssb <- SRdata$SSB
  
  N <- length(rec)
  
  #  if (SR=="HS") SRF <- function(x,a,b) a*(x+sqrt(b^2+gamma^2/4)-sqrt((x-b)^2+gamma^2/4))
  if (SR=="HS") SRF <- function(x,a,b) ifelse(x>b,b*a,x*a)
  if (SR=="BH") SRF <- function(x,a,b) a*x/(1+b*x)
  if (SR=="RI") SRF <- function(x,a,b) a*x*exp(-b*x)
  
  obj.f <- function(a,b,rho){
    resid <- sapply(1:N,function(i) log(rec[i]) - log(SRF(ssb[i],a,b)))
    resid2 <- NULL
    for (i in 1:N) {
      resid2[i] <- ifelse(i==1,resid[i], resid[i]-rho*resid2[i-1])
    }
    
    if (method == "L2") {
      sd <- sqrt(sum(resid2^2)/(N-rho^2))
      sd2 <- c(sd/sqrt(1-rho^2), rep(sd,N-1))
      obj <- -sum(w*dnorm(resid2,0,sd2,log=TRUE))
    } else {
      sd <- sum(abs(resid2))/(N-rho^2)
      sd2 <- c(sd/sqrt(1-rho^2), rep(sd,N-1))
      obj <- -sum(w*sapply(1:N, function(i){-log(2*sd2[i])-abs(resid2[i]/sd2[i])}))
    }
    return(obj)
  }
  
  a.range <- range(rec/ssb)
  b.range <- range(1/ssb)
  if (SR == "HS") b.range <- range(ssb)
  grids <- as.matrix(expand.grid(
    seq(a.range[1],a.range[2],len=length),
    seq(b.range[1],b.range[2],len=length)
  ))
  init <- as.numeric(grids[which.min(sapply(1:nrow(grids),function(i) obj.f(grids[i,1],grids[i,2],0))),])
  init[1] <- log(init[1])
  init[2] <- ifelse (SR == "HS",-log(max(0.000001,(max(ssb)-min(ssb))/max(init[2]-min(ssb),0.000001)-1)),log(init[2]))
  if (AR != 0) init[3] <- 0
  
  if (SR == "HS") { 
    if (AR == 0) {
      obj.f2 <- function(x) obj.f(exp(x[1]),min(ssb)+(max(ssb)-min(ssb))/(1+exp(-x[2])),0)
    } else {
      obj.f2 <-  function(x) obj.f(exp(x[1]),min(ssb)+(max(ssb)-min(ssb))/(1+exp(-x[2])),1/(1+exp(-x[3])))
    }
  } else {
    if (AR == 0) {
      obj.f2 <- function(x) obj.f(exp(x[1]),exp(x[2]),0)
    } else {
      obj.f2 <-  function(x) obj.f(exp(x[1]),exp(x[2]),1/(1+exp(-x[3])))
    }
  }
  
  opt <- optim(init,obj.f2)
  opt <- optim(opt$par,obj.f2,method="BFGS",hessian=hessian)
  
  Res <- list()
  Res$input <- arglist
  Res$opt <- opt
  
  a <- exp(opt$par[1])
  b <- ifelse(SR=="HS",min(ssb)+(max(ssb)-min(ssb))/(1+exp(-opt$par[2])),exp(opt$par[2]))
  rho <- ifelse(AR==0,0,1/(1+exp(-opt$par[3])))
  resid <- sapply(1:N,function(i) log(rec[i]) - log(SRF(ssb[i],a,b)))
  resid2 <- NULL
  for (i in 1:N) {
    resid2[i] <- ifelse(i == 1,resid[i], resid[i]-rho*resid2[i-1])
  }
  sd <- ifelse(method=="L2",sqrt(sum(resid2^2)/(N-rho^2)),sqrt(2)*sum(abs(resid2))/(N-rho^2))
  
  Res$resid <- resid
  Res$resid2 <- resid2
  
  Res$pars <- c(a,b,sd,rho)
  
  if (method!="L2") {
    if (AR!=0) {
      arres <- ar(resid,aic=FALSE,order.max=1)
      Res$pars[3] <- sqrt(arres$var.pred)
      Res$pars[4] <- arres$ar
    }
  }
  
  Res$loglik <- loglik <- -opt$value
  
  if (method=="L2") {
    if (TMB) {
      data <- list()
      data$rec <- rec
      data$ssb <- ssb
      if (SR=="HS") data$SR <- 0
      if (SR=="BH") data$SR <- 1
      if (SR=="RI") data$SR <- 2
      #      data$gamma <- gamma
      
      params <- list()
      params$rec_loga <- opt$par[1]
      params$rec_logb <- ifelse(SR=="HS",-log(Res$pars[2]),opt$par[2])
      params$log_sd <- log(Res$pars[3]/(sqrt(1-Res$pars[4]^2)))
      params$logit_rho <- ifelse(AR==0,-20,opt$par[3])
      
      map <- list()
      if (AR==0) map$logit_rho<-factor(NA)
      obj <- MakeADFun(data, params, map=map,DLL="autoregressiveSR2",silent=TRUE)
      lower <- obj$par*0-Inf
      upper <- obj$par*0+Inf
      
      if (SR == "HS") {
        lower["rec_logb"] <- -log(max(ssb))
        upper["rec_logb"] <- -log(min(ssb))
      }
      opt <- nlminb(obj$par, obj$fn, obj$gr, lower=lower, upper=upper)
      rep <- sdreport(obj)
      
      # grid search
      if (SR != "HS") {
        grids <- expand.grid(seq(opt$par[1]-2,opt$par[1]+2,length=5),
                             seq(opt$par[2]-2,opt$par[2]+2,length=5))
      } else {
        grids <- expand.grid(seq(opt$par[1]-2,opt$par[1]+2,length=5),
                             seq(-log(max(ssb)),-log(min(ssb)),length=5))
      }
      params2 <- params
      params2$log_sd <- opt$par[3]
      if (AR == 1) params2$logit_rho <- opt$par[4]
      for (j in 1:nrow(grids)) {
        params2$rec_loga <- grids[j,1]
        params2$rec_logb <- grids[j,2]
        obj2 <- MakeADFun(data, params2, map=map, DLL="autoregressiveSR2",silent=TRUE)
        opt2 <- nlminb(obj2$par, obj2$fn, obj2$gr, lower=lower, upper=upper)
        if (opt2$objective < opt$objective) {
          opt <- opt2
          obj <- obj2
          rep <- sdreport(obj2)
        }
      }
      
      Res$opt <- opt
      Res$rep <- rep
      if (SR=="HS") {
        Res$pars <- c(exp(rep$par.fixed[1]),1/exp(rep$par.fixed[2]),exp(rep$par.fixed[3]),ifelse(AR==0,0,1/(1+exp(-rep$par.fixed[4]))))
      } else {
        Res$pars <- c(exp(rep$par.fixed[1]),exp(rep$par.fixed[2]),exp(rep$par.fixed[3]),ifelse(AR==0,0,1/(1+exp(-rep$par.fixed[4]))))
      }
      Res$pars[3] <- sqrt(1-Res$pars[4]^2)*Res$pars[3]
      Res$loglik <- loglik <- -opt$objective
      
      a <- Res$pars[1]
      b <- Res$pars[2]
      rho <- Res$pars[4]
      resid <- sapply(1:N,function(i) log(rec[i]) - log(SRF(ssb[i],a,b)))
      resid2 <- NULL
      for (i in 1:N) {
        resid2[i] <- ifelse(i == 1,resid[i], resid[i]-rho*resid2[i-1])
      }
      Res$resid <- as.numeric(resid)
      Res$resid2 <- as.numeric(resid2)
    }
  }
  names(Res$pars) <- c("a","b","sd","rho")
  Res$pars <- data.frame(t(Res$pars))
  #  Res$gamma <- gamma
  
  ssb.tmp <- seq(from=0,to=max(ssb)*1.3,length=100)
  R.tmp <- sapply(1:length(ssb.tmp), function(i) SRF(ssb.tmp[i],a,b))
  pred.data <- data.frame(SSB=ssb.tmp,R=R.tmp)
  Res$pred <- pred.data
  
  Res$k <- k <- sum(Res$pars>0)
  Res$AIC <- -2*loglik+2*k
  Res$AICc <- Res$AIC+2*k*(k+1)/(N-k-1)
  Res$BIC <- -2*loglik+k*log(N)
  return(Res)
}
# Hockey-stick

plot.kobe <- function(vpares,Bmsy,Umsy,Blim=NULL,Bban=NULL,plot.history=FALSE,is.plot=FALSE,pickU="",pickB="",
                      ylab.tmp=ifelse(yaxis=="U","U/Umsy","F/Fmsy"),
                      xlab.tmp="SSB/SSBmsy",title.tmp="",HCR=NULL,
                      yaxis="U" # y���ɂȂɂ��Ƃ邩�BU�̏ꍇ�͋��l���BF�̏ꍇ�� F=-log(1-U)�Ƃ��Čv�Z����fishing mortality
                      ){ # HCR=list(beta=0.8)
    
    if (is.null(vpares$wcaa)) vpares$wcaa <- vpares$input$dat$caa * vpares$input$dat$waa
    vpares$TC.MT <- as.numeric(colSums(vpares$wcaa))
    U_history <- as.numeric(vpares$TC.MT)/as.numeric(colSums(vpares$baa,na.rm=T))
    F_history <- -log(1-U_history)
    F_msy <- -log(1-Umsy)
    UBdata <- data.frame(years=as.numeric(colnames(vpares$baa)),
                         U=U_history/Umsy,
                         B=as.numeric(colSums(vpares$ssb))/Bmsy,
                         F=F_history/F_msy)
    x <- UBdata$B
    if(yaxis=="U") y <- UBdata$U else y <- UBdata$F
    tmp <- x>0 & y>0
    x <- x[tmp]
    y <- y[tmp]
    UBdata <- UBdata[tmp,]

    if(!is.null(Blim)){
        Blim.percent <- Blim/Bmsy
    }
    else{
        Blim.percent <- 0.5
    }

    plot(x,
         y,type="n",xlim=c(0,ifelse(max(x)<2,2,max(x,na.rm=T))),
         ylim=c(0,ifelse(max(y,na.rm=T)<3,3,max(y,na.rm=T))),
         cex=c(1,rep(1,length(y)-2),3),ylab=ylab.tmp,xlab=xlab.tmp)
    polygon(c(-1,1,1,-1),c(-1,-1,1,1),col="khaki1",border=NA)
    polygon(c(1,6,6,1),c(-1,-1,1,1),col="olivedrab2",border=NA)
    polygon(c(1,6,6,1),c(1,1,6,6),col="khaki1",border=NA)
    polygon(c(-1,Blim.percent,Blim.percent,-1),c(1,1,6,6),col="indianred1",border=NA)
    polygon(c(Blim.percent,1,1,Blim.percent),c(1,1,6,6),col="tan1",border=NA)
    polygon(c(-1,Blim.percent,Blim.percent,-1),c(-1,-1,1,1),col="khaki2",border=NA)
    polygon(c(Blim.percent,1,1,Blim.percent),c(-1,-1,1,1),col="khaki1",border=NA)            
    axis(side=1:2)

    if(!is.null(HCR)){
        lines(c(Bban/Bmsy,Blim/Bmsy,6),c(0,0.8,0.8),lty=2)
    }


#      points(x,y,type="o",pch=c(3,rep(1,length(y)-2),20),col=c(1,rep(1,length(y)-2),1),cex=c(1,r
      points(x,y,type="l",pch=20,col=1,lwd=1)
      points(x,y,type="p",pch=20,col=gray(c(seq(from=0.7,to=0,length=length(x)))),cex=1.2)
      points(rev(x)[1],rev(y)[1],type="p",pch=20,cex=2.5)
    title(title.tmp,adj=0.8,line=-2)
    
    if(isTRUE(plot.history)){
      plot(UBdata$years,UBdata$U,type="b",ylab="U/Umsy",xlab="Year",ylim=c(0,max(y)))
      abline(h=1)
      plot(UBdata$years,UBdata$F,type="b",ylab="F/Fmsy",xlab="Year",ylim=c(0,max(y)))
      abline(h=1)      
      plot(UBdata$years,UBdata$B,type="b",ylab="SSB/SSBmsy",xlab="Year",ylim=c(0,max(y)))
      abline(h=1); abline(h=Blim.percent,lty=2)
    }


    invisible(UBdata)    
}

plot.waa <- function(vres){
    lm.list <- list()
    nage <- nrow(vres$naa)
    col.tmp <- rainbow(nage)    
    logx <- log(unlist(vres$naa))
    logy <- log(unlist(vres$input$dat$waa))
    ages <- as.numeric(rep(rownames(vres$naa),ncol(vres$naa)))
    u.age <- unique(ages)
    plot(logx,logy,col=col.tmp[1+ages],xlab="log(N)",ylab="log(weight)")
    for(i in 1:length(u.age)){
        tmp <- ages==u.age[i] & logy>-Inf & logx>-Inf
        if(sum(tmp,na.rm=TRUE)>0){
            lm.list[[i]] <- lm(logy[tmp]~logx[tmp])
            l.type <- ifelse(summary(lm.list[[i]])$coeff[2,4]<0.05,1,2)
            if(!is.na(l.type)) abline(lm.list[[i]],col=col.tmp[1+ages[i]],lty=l.type)
        }
    }
    title(vres$stockid,line=0.2)
    legend("bottomleft",lty=c(1:2,rep(1,nage)),
           col=c(1,1,col.tmp),
           legend=c("p<0.05","p>0.05",paste("Age",u.age)))    
    return(lm.list)
}

### parametric bootstrap usnig fit.SR
boot.SR <- function(Res,n=100,seed=1){
  N <- length(Res$input$SRdata$year)
  
#  if (Res$input$SR=="HS") SRF <- function(x,a,b,gamma=Res$gamma) a*(x+sqrt(b^2+gamma^2/4)-sqrt((x-b)^2+gamma^2/4))
  if (Res$input$SR=="HS") SRF <- function(x,a,b) ifelse(x>b,b*a,x*a) 
  if (Res$input$SR=="BH") SRF <- function(x,a,b) a*x/(1+b*x)
  if (Res$input$SR=="RI") SRF <- function(x,a,b) a*x*exp(-b*x)
  
  sd <- sapply(1:N, function(i) ifelse(i==1,Res$pars$sd/sqrt(1-Res$pars$rho^2),Res$pars$sd))
  
  set.seed(seed)
  lapply(1:n, function(j){
    N <- length(Res$input$SRdata$SSB)
    resids <- rnorm(N,0,sd)
    pred <- obs <- resid0 <- numeric(N)
    ssb <- Res$input$SRdata$SSB
    
    for(i in 1:N){
      pred[i] <- SRF(ssb[i],Res$pars$a,Res$pars$b)
      if (i==1) {
        obs[i] <- pred[i]*exp(resids[i])
      } else {
        obs[i] <- pred[i]*exp(Res$pars$rho*resid0[i-1])*exp(resids[i])
      }
      resid0[i] <- log(obs[i]/pred[i])
    }
    res.b <- Res
    res.b$input$SRdata$R <- obs
    res.b <- do.call(fit.SR, res.b$input)
    return(res.b)
  })
}

### profile likelihood
prof.lik <- function(Res,a=Res$pars$a,b=Res$pars$b,sd=Res$pars$sd,rho=Res$pars$rho) {
  SRdata <- Res$input$SRdata
  rec <- SRdata$R
  ssb <- SRdata$SSB
  N <- length(rec)
  SR <- Res$input$SR
  gamma <- Res$gamma
  method <- Res$input$method
  w <- Res$input$w
  
#  if (SR=="HS") SRF <- function(x,a,b) a*(x+sqrt(b^2+gamma^2/4)-sqrt((x-b)^2+gamma^2/4))
  if (SR=="HS") SRF <- function(x,a,b) ifelse(x>b,b*a,x*a)   
  if (SR=="BH") SRF <- function(x,a,b) a*x/(1+b*x)
  if (SR=="RI") SRF <- function(x,a,b) a*x*exp(-b*x)
  
  resid <- sapply(1:N,function(i) log(rec[i]) - log(SRF(ssb[i],a,b)))
  resid2 <- NULL
  for (i in 1:N) {
    resid2[i] <- ifelse(i==1,resid[i], resid[i]-rho*resid2[i-1])
  }
  
  obj <- NULL
  if (method == "L2") {
    for (i in 1:N) {
      if (i==1) {
        obj <- c(obj,-0.5*log(2*pi)-log(sd^2/(1-rho^2))-resid2[i]^2/(2*sd^2/(1-rho^2)))
      } else {
        obj <- c(obj, -0.5*log(2*pi)-0.5*log(sd^2)-resid2[i]^2/(2*sd^2))
      }
    }
  } else {
    for (i in 1:N) {
      if (i==1) {
        obj <- c(obj,-log(2*sqrt(sd^2/(1-rho^2)))-abs(resid2[i])/sqrt(sd^2/(1-rho^2)))
      } else {
        obj <- c(obj, -log(2*sd)-abs(resid2[i])/sd)
      }
    }
  }
  obj <- sum(w*obj) # exact likelihood
  return(exp(obj))
}



## ������ƕ��G��kobe.plot
# fouts�������̏����\���̌��ʁBbrefs�͕����̊Ǘ���l
get.kobemat2 <- function(fouts,brefs,xlim=NULL,target.prob=0.5){
#    brefs <- sort(brefs)
    years <- as.numeric(rownames(fouts[[1]]$vssb))        
    probs <- matrix(0,length(years),length(fouts))
    for(j in 1:ncol(brefs)){
        probs <- probs + foreach(i=1:length(fouts),.combine=cbind) %do%
            as.numeric(rowMeans(fouts[[i]]$vssb > brefs[i,j])>target.prob)
        }
    if(is.null(xlim)) xlim <- range(years)
    plot(range(years),
         range(0.5,nrow(brefs)+1.5),
         type="n",xlab="Years",cex=3,xlim=xlim,
         ylab="Strategies",yaxt="n")
    abline(h=1:ncol(brefs),v=years,col="gray")
    axis(side=2,at=1:nrow(brefs),label=rownames(brefs))

    require(RColorBrewer)
    cols <- brewer.pal(ncol(brefs), "Paired")

    for(i in 1:length(fouts)){
        points(years,rep(i,length(years)),
               col=cols[probs[,i]],pch=20,cex=3)
    }
    legend("topright",pch=20,cex=1,col=cols,ncol=ceiling(ncol(brefs)/2),
           legend=paste("Prob(B>",colnames(brefs),")>",round(target.prob*100),"%"))
}



Generation.Time <- function(vpares,
  maa.year=2014:2015,
  M.year=2014:2015,
  Plus = 19
){

  maa <- vpares$input$dat$maa
  maa <- rowMeans(maa[,colnames(maa) %in% maa.year,drop=F],na.rm=T)
  maa <- maa[!is.na(maa)]    
  M <- vpares$input$dat$M
  M <- rowMeans(M[,colnames(M) %in% M.year,drop=F],na.rm=T)
  M <- M[!is.na(M)]
    
  age <- as.numeric(names(maa))
  
  maa <- c(maa, rep(1,Plus))
  M <- c(M, rep(M[length(M)],Plus))
  
  age <- c(age, max(age)+1:Plus)
  
  A <- length(M)
    
  L <- c(1,exp(-cumsum(M[-A])))
  
  G <- sum(age*L*maa)/sum(L*maa)
  
  return(G)
}


###############################
#### �����ʂ̏�ς݃O���t������
###############################

plotBfish <- function(tres0,vpares, # SR.est�̌���
                      b.target,ssb.max=Inf,
                      biomass.scale=1000){
   
    ssb <- tres0$ssb.mean/biomass.scale
    
    tmp <- substr(colnames(tres0),1,5)=="TB-MA"
    tb <- tres0[,tmp]/biomass.scale 
    tb2 <- sapply(1:ncol(tb),function(x) apply(tb[,1:x,drop=F],1,sum,na.rm=T))
    
    tmp <- substr(colnames(tres0),1,5)=="TC-MA"
    tc <- tres0[,tmp]/biomass.scale 
    tc2 <- sapply(1:ncol(tc),function(x) apply(tc[,1:x,drop=F],1,sum,na.rm=T))
#    library(png)
#    {if(file.exists(pngfile)) image <- readPNG(pngfile)
#    else image <- NULL}

    year.tmp <- rev(colnames(vpares$ssb))[1:5]
    range1 <- c(0,min(ssb.max,max(ssb)))
    range2 <- range(as.data.frame(vpares$ssb)[as.character(year.tmp)])

    col.tmp1 <- rgb(40/255,96/255,163/255,seq(from=0.1,to=0.9,length=ncol(tc)))
    col.tmp2 <- rgb(100/255,200/255,44/255,seq(from=0.1,to=0.9,length=ncol(tc)))    
          
    ### plot of SSB
#    tb3 <- tb2[which(ssb<ssb.max),]
    matplot(ssb,tb2,type="n",ylab=paste("Total biomass (",biomass.scale," MT)",sep=""),xaxs="i",yaxs="i",
            xlab="SSB (1000MT)", xlim=range1,ylim=c(0,max(tb2)))
    # �ߋ��̎��n��
        matpoints(ssb,tb2[,1],type="l",lwd=2,col="gray",lty=3)
#        points(x <- colSums(vpares$ssb)/biomass.scale,
#               y <- colSums(vpares$baa)/biomass.scale,type="o",
#               col=gray(c(seq(from=0.7,to=0,length=length(x)))),pch=20,cex=1.2,
#               lwd=3)
#        text(x[1],y[1],colnames(x)[1],adj=0)
#text(rev(x[1]),rev(y)[1],rev(colnames(x))[1],adj=0)

    text(rep(ssb[10],ncol(tb2)),
         tb2[10,],
         paste(0:(ncol(tb2)-1),"y/o"))#,round(apply(vpares$input$dat$waa,1,mean),0)," g"),cex=1)

    ssb.hist <- range(colSums(vpares$ssb)/biomass.scale)
    polygon(c(ssb.hist,rev(ssb.hist)),c(0,0,max(tb2)*10,max(tb2)*10),col=gray(0.8),border=NA)
    abline(v=b.target,col="gray")
    

    ## �ςݏグ�O���t
    non.na <- !is.na(ssb)
    for(i in 1:ncol(tb2)) menplot(ssb[non.na], cbind(0,tb2)[non.na,i:(i+1)],col=col.tmp1[i],border=NA)
                                        #    title("Total biomass",line=-1,adj=0.1)
  
    ##  catch
    {if(!is.null(vpares$wcaa)) wcatch <- as.numeric(colSums(vpares$wcaa))
        else{
            wcatch <- as.numeric(colSums(vpares$input$dat$caa * vpares$input$dat$waa,na.rm=T))
        }}
        matplot(ssb,tc2,type="n",,xaxs="i",yaxs="i",ylab=paste("Catch (",biomass.scale," MT)",sep=""),
                xlab="SSB (1000MT)",
                ylim=c(0,max(tc2)*1.2),xlim=range1)

    polygon(c(ssb.hist,rev(ssb.hist)),c(0,0,max(tc2)*10,max(tc2)*10),col=gray(0.8),border=NA)
    abline(v=b.target,col="gray")

    for(i in 1:ncol(tc2)) menplot(ssb[non.na], cbind(0,tc2)[non.na,i:(i+1)],col=col.tmp2[i],border=NA)

    text(rep(ssb[10],ncol(tc2)),
         tc2[10,],
         paste(0:(ncol(tc2)-1),"y/o"),col="darkgreen")#,round(apply(vpares$input$dat$waa,1,mean),0)," g"),cex=1)    
                                        #    title("Total catch",line=-1,adj=0.1)

    if(0){
        plot(ssb,tres0$fmulti,type="n",lwd=2,xlim=range1,ylab="Fishing efforts",xlab="SSB (1000MT)")
        polygon(c(ssb.hist,rev(ssb.hist)),c(0,0,10,10),col=gray(0.8),border=NA)
        abline(v=b.target,col="gray")    
        points(ssb,tres0$fmulti,type="l",lwd=2,xlim=range1,ylab="Fishing efforts")    
        par(new=T)
        matplot(ssb,cbind(tres0$ssb.CV,tres0$catch.CV),xlim=range1,ylim=c(0,2),type="l",lty="22",col=3:4,lwd=2,axes=F,ylab="",xlab="")
        axis(side=4)
        mtext(side=4,"CV",cex=1,line=2.3)
    }
}

############## ��������쐬�֐� ##################3

future.vpa1 <- function(
     vpares,
     multi=1,
     nyear=50, # �����\���̔N��
     ABC.year=2018, # ABC���v�Z����N
     waa.year=2015:2016, # �����p�����[�^�̎Q�ƔN
     maa.year=2015:2016,
     M.year=2015:2016,
     seed=1,
     N=100,
     naa0=NULL,
     eaa0=NULL,
     beta=1,
     delta=0,
     Blim=0,
     Bban=0,
     Pope=FALSE,
     ssb0=NULL,
     faa0=NULL,
     # recfunc�ɑ΂������
     rec.arg=list(a=res1$pars[1],b=res1$pars[2],gamma=res1$gamma,
     sd=res1$pars[3],bias.correction=TRUE,rho=res1$pars[4],resid=res1$resid)
){

#    print(multi)
    argname <- ls()
    arglist <- lapply(argname,function(x) eval(parse(text=x)))
    names(arglist) <- argname
    
set.seed(seed)

lag <- as.numeric(rownames(vpares$input$dat$caa))[1]

nY <- ncol(vpares$input$dat$caa)
final.year <- as.numeric(colnames(vpares$input$dat$caa)[nY])

waa <- vpares$input$dat$waa
waa <- rowMeans(waa[,colnames(waa) %in% waa.year])
maa <- vpares$input$dat$maa
maa <- rowMeans(maa[,colnames(maa) %in% maa.year])
M <- vpares$input$dat$M
A <- nrow(M)
M <- rowMeans(M[,colnames(M) %in% M.year])

waa <- array(waa,dim=c(A,nyear+1,N))
maa <- array(maa,dim=c(A,nyear+1,N))
M <- array(M,dim=c(A,nyear+1,N))

naa <- baa <- ssb <- faa <- caa <- wcaa <- array(NA,dim=c(A,nyear+1,N))

if (is.null(faa0)) Fc.at.age <- vpares$Fc.at.age else Fc.at.age <- faa0

# 1st year

  if (is.null(naa0)) {
    waa[,1,] <- vpares$input$dat$waa[,nY]
    maa[,1,] <- vpares$input$dat$maa[,nY]
    M[,1,] <- vpares$input$dat$M[,nY]
    naa[,1,] <- vpares$naa[,nY] 
    faa[,1,] <- vpares$faa[,nY]
    baa[,1,] <- naa[,1,]*waa[,1,]
    ssb[,1,] <- baa[,1,]*maa[,1,]
    faa[,2,] <- Fc.at.age
    faa[,-(1:2),] <- multi*Fc.at.age
  } else {
    naa[,1,] <- naa0
    faa[,,] <- multi*Fc.at.age
    baa[,1,] <- naa[,1,]*waa[,1,]
    ssb[,1,] <- baa[,1,]*maa[,1,]
  }
  
eaa <- matrix(NA,nrow=nyear+1,ncol=N)

sd2 <- sqrt(rec.arg$sd^2/(1-rec.arg$rho^2))
if (is.null(eaa0)) eaa[1,] <- rec.arg$resid[length(rec.arg$resid)] else eaa[1,] <- eaa0

eaa[-1,] <- rnorm(nyear*N,0,rec.arg$sd)

if(class(ssb0)=="matrix") ssb0 <- array(ssb0,dim=c(A,1,N))

if (is.null(ssb0) & (2 - lag <= 0)) {
  ssb0 <- array(NA, dim=c(A,abs(2-lag)+1,N))
  for (j in 1:(abs(2-lag)+1)){
    ssb0[,j,] <- vpares$ssb[,nY-j]
  }
}

alpha <- array(1,dim=c(A,nyear+1,N))
 
# 2nd year and onward

for (i in 2:(nyear+1)){
  eaa[i,] <- rec.arg$rho*eaa[i-1,]+eaa[i,]
  naa[2:A,i,] <- naa[1:(A-1),i-1,]*exp(-M[1:(A-1),i-1,]-alpha[1:(A-1),i-1,]*faa[1:(A-1),i-1,])
  naa[A,i,] <- naa[A,i,]+naa[A,i-1,]*exp(-M[A,i-1,]-alpha[A,i-1,]*faa[A,i-1,])
  ssb[,i,] <- naa[,i,]*waa[,i,]*maa[,i,]
  if(i-lag > 0) SSB <- colSums(ssb[,i-lag,,drop=FALSE],na.rm=TRUE) else SSB <- colSums(ssb0[,i-1,,drop=FALSE])
  naa[1,i,] <- HS(SSB,rec.arg$a,rec.arg$b,rec.arg$gamma,HStype="HS")*exp(eaa[i,]-0.5*sd2^2)
  baa[,i,] <- naa[,i,]*waa[,i,]
  ssb[,i,] <- baa[,i,]*maa[,i,]
  Bcur <- colSums(ssb[,i,,drop=FALSE],na.rm=TRUE)
  alpha[,i,] <- beta*matrix(ifelse(Bcur > Blim, 1, ifelse(Bcur > Bban, ((Bcur-Bban)/(Blim-Bban))^delta, 0)),byrow=TRUE,nrow=A,ncol=N)
}

  if (Pope) caa <- (1-exp(-alpha*faa))*exp(-M/2)*naa else caa <- naa*(1-exp(-alpha*faa-M))*alpha*faa/(alpha*faa+M)

  wcaa <- caa*waa
  vwcaa <- apply(wcaa,c(2,3),sum,na.rm=T)

res <- list(beta=beta,delta=delta,alpha=alpha,Blim=Blim,Bban=Bban,waa=waa,maa=maa,M=M,naa=naa,baa=baa,ssb=ssb,faa=faa,caa=caa,wcaa=wcaa,vwcaa=vwcaa,eaa=eaa,multi=multi,input=arglist)
}

#

HS <- function(x,a,b,gamma1=0.001,HStype="HS") if (HStype=="Mesnil") a*(x+sqrt(b^2+(gamma1^2)/4)-sqrt((x-b)^2+(gamma1^2)/4)) else ifelse(x > b, a*b, a*x)

##

est.MSY2 <- function(vpares,N=1000,res1=NULL,sim0=NULL,nyear=NULL,pgy=0.9,lim=0.6,ban=0.1,mY=5,long.term=20,
                     Fmsy.max=3, # current F��Fmsy�ɔ�ׂď���������ꍇ�A���܂��������Ȃ��ꍇ������܂��B���̂Ƃ��͂��̃I�v�V������Fmsy.max=10�Ƃ����Ă��������B
                     Fmsy.step=0.1,thin=1,inc=1,SRtype="L2",fm=5,tol=NULL,
                     AutoCor=FALSE,# �֐������Ŏ��ȑ��֌W���𐄒肷�邩 "future.vpa"���g���ꍇ�͂ǂ���ł��ǂ�
                     AutoCorOut=FALSE, # �t�B�b�g���������Ǝc���̎��ȑ��ւ��v�Z����ꍇ
                     current.resid=0, # �ŋߔN���N���̎��ȑ��ւ𕽋ς��邩
                     future.function.name="future.vpa1",seed=1){
 
  if (is.null(tol)) tol <- .Machine$double.eps^0.25
 
  Ccur <- sum(tail(t(vpares$input$dat$caa*vpares$input$dat$waa),1),na.rm=TRUE)
  Blim.cur <- vpares$Blim

  A <- nrow(vpares$input$dat$caa)

  if (is.na(vpares$Fc.at.age[length(vpares$Fc.at.age)])){
    vpares$input$dat$caa <- vpares$input$dat$caa[-A,]
    vpares$input$dat$waa <- vpares$input$dat$waa[-A,]
    vpares$input$dat$maa <- vpares$input$dat$maa[-A,]
    vpares$input$dat$M <- vpares$input$dat$M[-A,]
    vpares$naa <- vpares$naa[-A,]
    vpares$faa <- vpares$faa[-A,]  
    vpares$Fc.at.age <- vpares$Fc.at.age[-A]
    vpares$ssb[is.na(vpares$ssb)] <- 0
    A <- A-1
  }

  vpares$Fc.at.age <- fm*vpares$Fc.at.age

  SRdata <- get.SRdata(vpares) 

# fit SR
  
  if (is.null(res1) && is.null(sim0)){
      res0 <- estSR(SRdata,SR="HS",type=SRtype,Length=20,rho.range=0,AutoCor=FALSE) 
      if (AutoCor){
          res1 <- estSR(SRdata,SR="HS",type=SRtype,Length=20,rho.range=0,AutoCor=AutoCor)
          if (res0$AICc <= res1$AICc) res1 <- res0
#          if(!is.null(res0$aic)) if(res0$aic <= res1$aic) res1 <- res0
#          if(!is.null(res0$AICc)) if(res0$AICc <= res1$AICc) res1 <- res0      
      } else{
          res1 <- res0
      }
  }
    
  if (class(res1$pars)!="numeric") res1$pars <- as.numeric(res1$pars)
  
  if (AutoCorOut){
    ar1 <- ar(ts(res1$resid),order.max=1)
    rho <- ar1$ar
    if (length(rho)==0) rho <- 0
    if (abs(rho) >= 0.99) rho <- sign(rho)*0.99
    res1$pars[3] <- sqrt(ar1$var.pred)
    res1$pars[4] <- rho
  }
    
  if (current.resid > 0) w.recent <- mean(rev(res1$resid)[1:current.resid]) else w.recent <- 0
  
# Initial Setting

    lag <- as.numeric(rownames(vpares$input$dat$caa))[1]
    
    Pope <- vpares$input$Pope
    future.vpa1 <- get(future.function.name)

    years <- sort(as.numeric(rev(names(vpares$naa))[1:5]))
    
    Surv <- exp(-tail(t(vpares$input$dat$M),1))
    
    L <- cumprod(Surv)
    L[A-1] <- L[A-1]/(1-Surv[A])
    L <- c(1,L[1:(A-1)])
    
    GT <- Generation.Time(vpares,maa.year=years,M.year=years)  # Generation Time
    GT2 <- round(GT*2)
    
    det.naa0 <- res1$pars[1]*res1$pars[2]*L
    
    waa <- vpares$input$dat$waa
    waa <- rowMeans(waa[,colnames(waa) %in% years])
    maa <- vpares$input$dat$maa
    maa <- rowMeans(maa[,colnames(maa) %in% years])
    
    det.B0 <-  sum(det.naa0*waa*maa)
    
    if(is.null(nyear)) nyear <- round(GT*long.term)
    
    if (is.null(sim0)){
       sim0 <- future.vpa1(vpares,
                   multi=0,
                   nyear=nyear, # �����\���̔N��
                   N=N, # �m���I�v�Z�̌J��Ԃ���
                   ABC.year=max(years)+1, # ABC���v�Z����N
                   waa.year=years, # �����p�����[�^�̎Q�ƔN
                   maa.year=years,
                   M.year=years,
                   seed=seed,
                   naa0=det.naa0,
                   Pope=Pope,
                   # recfunc�ɑ΂������
                   rec.arg=list(a=res1$pars[1],b=res1$pars[2],gamma=res1$gamma,sd=res1$pars[3],bias.correction=TRUE,rho=res1$pars[4],resid=res1$resid)
      )

    sim1 <- future.vpa1(vpares,
                   multi=1,
                   nyear=nyear, # �����\���̔N��
                   N=1, # �m���I�v�Z�̌J��Ԃ���
                   ABC.year=max(years)+1, # ABC���v�Z����N
                   waa.year=years, # �����p�����[�^�̎Q�ƔN
                   maa.year=years,
                   M.year=years,
                   seed=seed,
                   naa0=det.naa0,
                   Pope=Pope,
                   # recfunc�ɑ΂������
                   rec.arg=list(a=res1$pars[1],b=res1$pars[2],gamma=res1$gamma,sd=res1$pars[3],bias.correction=TRUE,rho=res1$pars[4],resid=res1$resid)
                   )
    } else{
        farg <- sim0$input
        farg$N <- N
        farg$nyear <- nyear
        farg$multi <- 0
        farg$ABC.year <- max(years)+1
        farg$naa0 <- det.naa0
        if(!is.null(farg$pre.catch)){
            farg$pre.catch <- NULL # pre.catch�I�v�V����������Ƃ��܂������Ȃ��̂łȂ��������Ƃɂ���
            cat("notice: option \"pre.catch\" is turned off in estimating MSY.\n")
        }
        if(!is.null(farg$rec.new)){
            farg$rec.new <- NULL # rec.new�v�V����������Ƃ��܂������Ȃ��̂łȂ��������Ƃɂ���
            cat("notice: option \"rec.new\" is turned off in estimating MSY.\n")            
        }
        farg$add.year <- 1
        farg$is.plot <- FALSE
        farg$silent <- TRUE
        farg$det.run <- FALSE
        sim0 <- do.call(future.vpa1,farg)

        farg$N <- 2
        farg$multi <- 1
        sim1 <- do.call(future.vpa1,farg)
    }
    
##    MSY����

    farg <- sim1$input
    nY <- nyear+1
    eyear <- mY+(lag > 0)*(lag-1)
    
    syfunc <- function(x,farg,nyear=50,N=100,eyear=4,naa0=NULL,eaa0=NULL,ssb0=NULL,faa0=NULL,sd=NULL){
      farg$multi <- x
      farg$N <- N
      farg$nyear <- nyear
      farg$naa0 <- naa0
      farg$eaa0 <- eaa0
      farg$ssb0 <- ssb0
      farg$faa0 <- faa0
      if (!is.null(sd)) farg$rec.arg$sd <- sd
      fout <- do.call(future.vpa1,farg)
      
      nY <- nyear+1
      
      out <- list(catch=fout$vwcaa[(nY-(eyear-1)):nY,,drop=FALSE],ssb=fout$ssb[,(nY-(eyear-1)):nY,,drop=FALSE],naa=fout$naa[,(nY-(eyear-1)):nY,,drop=FALSE],baa=fout$baa[,(nY-(eyear-1)):nY,,drop=FALSE],eaa=fout$eaa[(nY-(eyear-1)):nY,,drop=FALSE])
      return(out)
    }
    
    F.multi <- seq(0,Fmsy.max,by=Fmsy.step)
    
    N0 <- sim0$naa[,nY,]
    e0 <- sim0$eaa[nY,]
    
    if(lag==0) SSB0 <- NULL else SSB0 <- sim0$ssb[,nY-(lag-1),]
    
    FSYest <- lapply(F.multi, function(x) syfunc(x,farg,N=round(N/thin),nyear=nyear,eyear=eyear,naa0=N0[,1:round(N/thin)],eaa=e0[1:round(N/thin)],ssb0=SSB0[,1:round(N/thin)])) 
    
    FSYest.c <- sapply(1:length(F.multi), function(i) mean(FSYest[[i]]$catch))
    
    num.msy <- which.max(FSYest.c)
    
    num.msy0 <- num.msy
    
    Fmsy.multi <- F.multi[num.msy]
  
    obj.msy <- function(x) -mean(syfunc(x,farg,N=N,nyear=nyear,eyear=eyear,naa0=N0,eaa0=e0,ssb0=SSB0)$catch)
    res.msy <- optimize(obj.msy, pmin(pmax(c(Fmsy.multi-inc*Fmsy.step,Fmsy.multi+inc*Fmsy.step),min(F.multi)),max(F.multi)),tol=tol)
      
    Fmsy.multi <- res.msy$minimum
    MSY <- -res.msy$objective
    MSYres <- syfunc(Fmsy.multi,farg,N=N,nyear=nyear,eyear=eyear,naa0=N0,eaa0=e0,ssb0=SSB0)
    ssb.msy <- mean(apply(MSYres$ssb,c(2,3),sum,na.rm=TRUE))
   
##    PGY����
  
    id.pgy0 <- num.msy0:length(F.multi)
    id.pgy <- which.min((FSYest.c[id.pgy0] - pgy*MSY)^2)
    
    pgy.low <- id.pgy0[id.pgy]
    
    Flow <- F.multi[pgy.low]
    
    N.m <- MSYres$naa[,eyear,]
    e.m <- MSYres$eaa[eyear,]
    if(lag==0) SSB.m <- NULL else SSB.m <- MSYres$ssb[,eyear-(lag-1),]
    
    obj.pgy <- function(x) (mean(syfunc(x,farg,N=N,nyear=nyear,eyear=eyear,naa0=N.m,eaa0=e.m,ssb0=SSB.m)$catch)-pgy*MSY)^2
    res.pgy <- optimize(obj.pgy, pmin(pmax(c(Flow-inc*Fmsy.step,Flow+inc*Fmsy.step),Fmsy.multi),max(F.multi)),tol=tol)
      
    Flow.multi <- res.pgy$minimum
    PGYlow.res <- syfunc(Flow.multi,farg,N=N,nyear=nyear,eyear=eyear,naa0=N.m,eaa0=e.m,ssb0=SSB.m)
    PGYlow <- mean(PGYlow.res$catch)
    ssb.low <- mean(apply(PGYlow.res$ssb,c(2,3),sum,na.rm=T))
    
    id.pgy0 <- 1:num.msy0
    id.pgy <- which.min((FSYest.c[id.pgy0] - pgy*MSY)^2)
    
    pgy.high <- id.pgy0[id.pgy]
    
    Fhigh <- F.multi[pgy.high]
    
    res.pgy <- optimize(obj.pgy, pmin(pmax(c(Fhigh-inc*Fmsy.step,Fhigh+inc*Fmsy.step),min(F.multi)),Fmsy.multi),tol=tol)
      
    Fhigh.multi <- res.pgy$minimum
    PGYhigh.res <- syfunc(Fhigh.multi,farg,N=N,nyear=nyear,eyear=eyear,naa0=N.m,eaa0=e.m,ssb0=SSB.m)
    PGYhigh <- mean(PGYhigh.res$catch)
    ssb.high <- mean(apply(PGYhigh.res$ssb,c(2,3),sum,na.rm=T))
    
##  Bhs����

    if(res1$input$SR=="HS"){
        det.Bhs <- res1$pars[2]
    
        if (!is.null(SSB0)) SSB0.HS <- as.matrix(rowMeans(SSB0)) else SSB0.HS <- NULL
    
        obj.HS <- function(x) sum(syfunc(x,farg,N=2,nyear=nyear,eyear=eyear,naa0=as.matrix(rowMeans(N0)),eaa0=NULL,ssb0=SSB0.HS,sd=0)$ssb[,eyear,1])-det.Bhs
    res.HS <- uniroot(obj.HS, c(0,2*max(F.multi)),tol=tol)
    
        FHS.multi <- res.HS$root

        HSres <- syfunc(FHS.multi,farg,N=N,nyear=nyear,eyear=eyear,naa0=N0,eaa0=e0,ssb0=SSB0)
        HScat <- mean(HSres$catch)
        ssb.hs <- mean(apply(HSres$ssb,c(2,3),sum,na.rm=T))
    }
    else{
        det.Bhs <- SSB0.HS <- obj.HS <- res.HS <- FHS.multi <- HSres <- HScat <- ssb.hs <- NULL
    }

##  target function

    # ���ۂɂ͍Ō�̍Đ��Y�֌W�̎c��������Ă��K�v������i���ȑ��ւ�����Ƃ��ɕK�v�j
    
    ##    target.func <- function(x,farg,naa0=NULL,eaa0=NULL,ssb0=NULL,faa0=NULL,mY=5,N=1,seed=1,eyear=4,p=1,beta=1,delta=0,Blim=0,Bban=0,sd0=NULL){
    target.func <- function(x,farg,naa0=NULL,eaa0=NULL,ssb0=NULL,faa0=NULL,mY=5,N=2,seed=1,eyear=4,p=1,beta=1,delta=0,Blim=0,Bban=0,sd0=NULL){    
      farg$multi <- x
      farg$seed <- seed
      farg$N <- N
      farg$nyear <- mY
      farg$naa0 <- p*naa0
      farg$eaa0 <- eaa0
      farg$ssb0 <- p*ssb0
      farg$faa0 <- faa0
      farg$beta <- beta
      farg$delta <- delta
      farg$Blim <- Blim
      farg$Bban <- Bban
      if(!is.null(farg$ABC.year)) farg$ABC.year <- farg$start.year
      if (!is.null(sd0)) farg$rec.arg$sd <- sd0
      fout <- do.call(future.vpa1,farg)
      
      nY <- mY+1
      
      out <- list(catch=fout$vwcaa[(nY-(eyear-1)):nY,,drop=FALSE],ssb=fout$ssb[,(nY-(eyear-1)):nY,,drop=FALSE],naa=fout$naa[,(nY-(eyear-1)):nY,,drop=FALSE],baa=fout$baa[,(nY-(eyear-1)):nY,,drop=FALSE],eaa=fout$eaa[(nY-(eyear-1)):nY,,drop=FALSE])
      return(out)
    }

##  Blim0����
    
    Lim0.res <- LIMtoLOW <- list()
    Flim.multi <- Lim0 <- ssb.lim0 <- PRT.lim <- numeric(length(lim))
    
    PRT.range <- 1:(4*GT2)
    
    N.m <- MSYres$naa[,eyear,]
    e.m <- MSYres$eaa[eyear,]
    if(lag==0) SSB.m <- NULL else SSB.m <- MSYres$ssb[,eyear-(lag-1),]
      
    for (j in 1:length(lim)){
      id.lim0 <- num.msy0:length(F.multi)
      id.lim <- which.min((FSYest.c[id.lim0] - lim[j]*MSY)^2)
    
      lim.num <- id.lim0[id.lim]
    
      Flim <- F.multi[lim.num]
        
      obj.lim <- function(x) (mean(syfunc(x,farg,N=N,nyear=nyear,eyear=eyear,naa0=N.m,eaa0=e.m,ssb0=SSB.m)$catch)-lim[j]*MSY)^2
      res.lim <- optimize(obj.lim, pmin(pmax(c(Flim-inc*Fmsy.step,Flim+inc*Fmsy.step),Fmsy.multi),max(F.multi)),tol=tol)
      
      Flim.multi[j] <- res.lim$minimum
      Lim0.res[[j]] <- syfunc(Flim.multi[[j]],farg,N=N,nyear=nyear,eyear=eyear,naa0=N.m,eaa0=e.m,ssb0=SSB.m)
      Lim0[j] <- mean(Lim0.res[[j]]$catch)
      ssb.lim0[j] <- mean(apply(Lim0.res[[j]]$ssb,c(2,3),sum,na.rm=T))
    
      ## PRT
      
        N.p <- Lim0.res[[j]]$naa[,eyear,]
        e.p <- Lim0.res[[j]]$eaa[eyear,]
    
        if(lag==0) SSB.p <- NULL else SSB.p <- Lim0.res[[j]]$ssb[,eyear-(lag-1),]
  
        LIMtoLOW[[j]] <- target.func(Fmsy.multi,farg,mY=4*GT2,seed=seed,N=N,eyear=4*GT2,naa0=N.p,eaa0=e.p,ssb0=SSB.p)  
            
        LIMtoLOW.ssb <- sapply(PRT.range, function(x) mean(colSums(LIMtoLOW[[j]]$ssb[,x,])))
    
        PRT.lim[j] <- min(which(LIMtoLOW.ssb >= ssb.low))
    }

    ## PRT.lim <= mY�𖞂������̂�����Ȃ�warning��Ԃ����Ƃ����邪�A���u���Ă��܂��i�g���Ă��Ȃ��v�Z���ʂȂ̂Łj
    nlim.est <- min(which(PRT.lim <= mY))
    if(is.na(nlim.est) | nlim.est == Inf) nlim.est <- length(lim)
    
    lim1 <- lim[nlim.est]
    Lim1.res <- Lim0.res[[nlim.est]]
    Flim1.multi <- Flim.multi[nlim.est]
    Lim1 <- Lim0[nlim.est]
    ssb.lim1 <- ssb.lim0[nlim.est]
    PRT.lim1 <- PRT.lim[nlim.est]
    
##  Bban0����

    Ban0.res <- BANtoLIM <- list()
    Fban.multi <- Ban0 <- ssb.ban0 <- PRT.ban <- numeric(length(ban))
    
    for (j in 1:length(ban)){    
      id.ban0 <- num.msy0:length(F.multi)
      id.ban <- which.min((FSYest.c[id.ban0] - ban[j]*MSY)^2)
    
      ban.num <- id.ban0[id.ban]
    
      Fban <- F.multi[ban.num]
        
      obj.ban <- function(x) (mean(syfunc(x,farg,N=N,nyear=nyear,eyear=eyear,naa0=N.m,eaa0=e.m,ssb0=SSB.m)$catch)-ban[j]*MSY)^2
      res.ban <- optimize(obj.ban, pmin(pmax(c(Fban-inc*Fmsy.step,Fban+inc*Fmsy.step),Fmsy.multi),max(F.multi)),tol=tol)
      
      Fban.multi[j] <- res.ban$minimum
      Ban0.res[[j]] <- syfunc(Fban.multi[j],farg,N=N,nyear=nyear,eyear=eyear,naa0=N.m,eaa0=e.m,ssb0=SSB.m)
      Ban0[j] <- mean(Ban0.res[[j]]$catch)
      ssb.ban0[j] <- mean(apply(Ban0.res[[j]]$ssb,c(2,3),sum,na.rm=T))
      
      ## PRT
      
        N.p <- Ban0.res[[j]]$naa[,eyear,]
        e.p <- Ban0.res[[j]]$eaa[eyear,]
    
        if(lag==0) SSB.p <- NULL else SSB.p <- Ban0.res[[j]]$ssb[,eyear-(lag-1),]
  
        BANtoLIM[[j]] <- target.func(Fmsy.multi,farg,mY=4*GT2,seed=seed,N=N,eyear=4*GT2,naa0=N.p,eaa0=e.p,ssb0=SSB.p,delta=1,Blim=ssb.lim1,Bban=ssb.ban0[j])  
            
        BANtoLIM.ssb <- sapply(PRT.range, function(x) mean(colSums(BANtoLIM[[j]]$ssb[,x,])))
    
        PRT.ban[j] <- min(which(BANtoLIM.ssb >= ssb.lim1))
    }
    
    nban.est <- min(which(PRT.ban <= mY))
    if(is.na(nban.est) | nban.est == Inf) nban.est <- length(ban)
    
    ban1 <- ban[nban.est]
    Ban1.res <- Ban0.res[[nban.est]]
    Fban1.multi <- Fban.multi[nban.est]
    Ban1 <- Ban0[nban.est]
    ssb.ban1 <- ssb.ban0[nban.est]
    PRT.ban1 <- PRT.ban[nban.est]
    
## Btarget����

    ## Btarget
    
    Ftar.multi <- Fmsy.multi
    eyear <- mY+(lag > 0)*(lag-1)
    
    N.m <- MSYres$naa[,eyear,]
    e.m <- MSYres$eaa[eyear,]
    if(lag==0) SSB.m <- NULL else SSB.m <- MSYres$ssb[,eyear-(lag-1),]
    
    TARres <- target.func(Ftar.multi,farg,mY=mY,seed=seed,N=N,eyear=mY,naa0=N.m,eaa0=e.m+w.recent,ssb0=SSB.m)
    Btar <- mean(colSums(TARres$ssb[,mY,]))
    
    # Blow ����
    
    N.low <- PGYlow.res$naa[,1+(lag>0)*(lag-1),]
    e.low <- PGYlow.res$eaa[1+(lag>0)*(lag-1),]
#    if(lag==0) SSB.low <- NULL else SSB.low <- PGYlow.res$ssb[,1,]
    if(lag==0) SSB.low <- NULL else SSB.low <- PGYlow.res$ssb[,eyear-(lag-1),]

    
    LOWres <- target.func(Flow.multi,farg,mY=mY,seed=seed,N=N,eyear=mY,naa0=N.low,eaa0=e.low+w.recent,ssb0=SSB.low)

    Blow <- mean(colSums(LOWres$ssb[,mY,]))
    
    P.low <- Blow/Btar
    
    # Blim ����
    
    N.lim <- Lim1.res$naa[,1+(lag>0)*(lag-1),]
    e.lim <- Lim1.res$eaa[1+(lag>0)*(lag-1),]
                                        #    if(lag==0) SSB.lim <- NULL else SSB.lim <- Lim1.res$ssb[,1,]
    if(lag==0) SSB.lim <- NULL else SSB.lim <- Lim1.res$ssb[,eyear-(lag-1),]    
    
    LIMres <- target.func(Flim1.multi,farg,mY=mY,seed=seed,N=N,eyear=mY,naa0=N.lim,eaa0=e.lim+w.recent,ssb0=SSB.lim)

    Blim <- mean(colSums(LIMres$ssb[,mY,]))
    
    P.lim <- Blim/Btar
    
    # Bban ����
    
    N.ban <- Ban1.res$naa[,1+(lag>0)*(lag-1),]
    e.ban <- Ban1.res$eaa[1+(lag>0)*(lag-1),]
    ##    if(lag==0) SSB.ban <- NULL else SSB.ban <- Ban1.res$ssb[,1,]
    if(lag==0) SSB.ban <- NULL else SSB.ban <- Ban1.res$ssb[,eyear-(lag-1),]    
    
    BANres <- target.func(Fban1.multi,farg,mY=mY,seed=seed,N=N,eyear=mY,naa0=N.ban,eaa0=e.ban+w.recent,ssb0=SSB.ban)

    Bban <- mean(colSums(BANres$ssb[,mY,]))
    
    P.ban <- Bban/Btar
    
    Pref <- c(P.low, P.lim, P.ban)
    names(Pref) <- c("Low","Lim","Ban")

    if(0){
        # plot�͂��Ȃ�
        x.range <- range(SRdata$SSB,Btar,Bban)
        plot(SRdata$SSB, SRdata$R,xlab="SSB",ylab="R",pch=16,col="blue",cex=1.2,xlim=x.range)
        x.SSB <- seq(0,x.range[2],len=100)
        lines(x.SSB,HS(x.SSB,res1$pars[1],res1$pars[2]),col="pink",lwd=3)
        abline(v=Btar,col="green",lwd=3,lty=2)
        abline(v=Blim,col="orange",lwd=3,lty=2)
        abline(v=Bban,col="red",lwd=3,lty=2)
    }
  
    if(0){
      argname <- ls()
      arglist <- lapply(argname,function(x) eval(parse(text=x)))
      names(arglist) <- argname
      arglist$MSYres <- NULL
      arglist$PGYlow.res <- NULL    
      invisible(arglist)
    }
  
    out <- list(
      stockid=vpares$stockid,
      seed=seed,
      SRdata=SRdata,
      res1=res1,
      det.B0=det.B0,
      det.Bhs=det.Bhs,
      B0=mean(colSums(sim0$ssb[,nY,])),
      Bmsy=ssb.msy,
      Bpgy.low=ssb.low,
      Bpgy.high=ssb.high,
      Blim1=ssb.lim1,
      Bban1=ssb.ban1,
      Btar=Btar,
      Blow=Blow,
      Blim=Blim,
      Bban=Bban,
      Bhs=ssb.hs,
      pgy=pgy,
      lim=lim,
      ban=ban,
      fm=fm,
      lag=lag,
      eyear=eyear,
      Fmsy=Fmsy.multi,
      Flow=Flow.multi,
      Fhigh=Fhigh.multi,
      Flim=Flim1.multi,
      Fban=Fban1.multi,
      Fhs=FHS.multi,
      farg=farg,
      N=N,
      GT=GT,
      sim0=sim0,
      w.recent=w.recent,
      nyear=nyear,
      MSYres=MSYres,
      lim.est=lim1,
      ban.est=ban1,
      PRT.lim0=PRT.lim,
      PRT.ban0=PRT.ban,      
      PRT.lim=PRT.lim1,
      PRT.ban=PRT.ban1,
      PGYlow.res=PGYlow.res,
      PGYhigh.res=PGYhigh.res,
      TARres=TARres,
      LOWres=LOWres,
      Lim0.res=Lim0.res,
      Ban0.res=Ban0.res,
      Lim1.res=Lim1.res,
      Ban1.res=Ban1.res,      
      LIMres=LIMres,
      BANres=BANres,
      HSres=HSres,
      Pref=Pref,
      syfunc=syfunc,
      target.func=target.func,
      future.function.name=future.function.name,
      Blim.cur=Blim.cur,
      Ccur=Ccur
    )

    b.table <- unlist(out[c("Bmsy","Btar","Fmsy","Bpgy.low","Blow","Flow",
                             "Blim1","Blim","Flim","Bban1","Bban","Fban")])
#    names(b.table) <- c("Bmsy\n(Equiribrium)","Bmsy\n(with AR)=Btarget","Fmsy",
#                         "Bpgy90%-low\n(Equiribrium)","Bpgy90%-low\n(with AR)=Blow","Flow")
#    b.limit <- c(out$Blim0,out$Blim,out$Flim,out$Bban0,out$Bban,out$Fban)
    b.table <- t(matrix(b.table,3,4))
#    b.table[,1:2] <- b.table[,1:2]/1000
    b.table <- cbind(apply(b.table[,1:2],2, function(x) round(as.numeric(x),0)),
                     round(b.table[,3],2))
    w.recent2 <- ifelse(is.null(sim0$input$rec.arg$rho),NA,w.recent)
    b.table <- rbind(b.table,c(NA,w.recent2,NA))
    colnames(b.table) <- c("Equiribrium","with AR","Fref/Fcurrent")
    rownames(b.table) <- c("Bmsy","B_pgy_90%_L","B_limit (B_pgy_60%_L)","B_ban (B_pgy_10%_L)","Recent residual")
    
    out$summary <- b.table
    
    return(out)
}

##
## ABC Calculation
##

### usage
## calc.beta(MSY.HS$input$msy,Ftar=refs$Fmsy,Btar=refs$Bmsy,Blim=refs$Blim,Bban=refs$Bban,N=1000)
calc.beta <- function(msy.input,Ftar=NULL,Btar=NULL,Blim=NULL,Bban=NULL,Blim.prob=0.9,Btar.prob=0.5,N=1000){
    input.beta <- msy.input
    input.beta$N <- N
    input.beta$multi <- Ftar    
    ## Blim, Bban�����Ƃɂ���HCR���g���ď����\�������{���邽�߂̃I�v�V������ǉ�
    input.beta$HCR <- list(Blim=Blim,
                           Bban=Bban,
                           beta=1) # ���̂Ƃ��̃x�[�^��T�����邪�A�����ł͂Ƃ肠�����P�Ƃ��Ă���
    input.beta$is.plot <- FALSE
    input.beta$Frec <- list(stochastic=TRUE,
                            future.year=NULL, # NULL�ɂ��Ă����Ə����\���̍ŏI�N�̊m��������
                            Blimit=Blim,
                            scenario="blimit", # �����̐e�������ʂ�Blimit�Ŏw�肵���l���Q�Ƃ��Č��߂�
                            target.probs=100-Blim.prob*100) # Blimit�u�ȉ��v�ɂȂ�m����ݒ�
    fres.beta1 <- do.call(future.vpa,input.beta) 

    input.beta$Frec <- list(stochastic=TRUE,
                            future.year=NULL, # NULL�ɂ��Ă����Ə����\���̍ŏI�N�Ɣ��f����
                            Blimit=Btar,
                            scenario="blimit",target.probs=100-Btar.prob*100)
    fres.beta2 <- do.call(future.vpa,input.beta)

    beta <- min(fres.beta1$multi/Ftar, fres.beta2$multi/Ftar)

    input.beta$multi <- beta*Ftar
    input.beta$Frec <- NULL
    
    fout <- do.call(future.vpa,input.beta)
    cat("beta:",beta,"\n",
        "Year:",rev(dimnames(fout$vssb)[[1]])[1],"\n",
        "Prob(SSB>Btar):",mean(fout$vssb[nrow(fout$vssb),]>Btar)*100,"\n",
        "Prob(SSB>Blim):",mean(fout$vssb[nrow(fout$vssb),]>Blim)*100,"\n")
    return(beta)
}

## ��������쐬�o�[�W�����B�V�����֐��ɍ����ւ�
calc.beta0 <- function(res,mY=5,prob.beta=c(0.5,0.9),prob.delta=c(0.9,0.95),beta=1,delta=1,beta.est=TRUE,delta.est=FALSE,beta.range=c(0,1),delta.range=c(0.1,5),Fm2.max=5,thin=1,step1=0.2,tol=0.0001,
                      Btar=res$Btar, # ���������A�e��Ǘ���l�͊O����ł��^������悤�ɂ���
                      Blow=res$Blow,
                      Blim=res$Blim,
                      Bban=res$Bban,
                      Fmsy=res$Fmsy)
{
  stockid <- res$stockid
  farg <- res$farg
  N <- res$N
  GT <- res$GT
  sim0 <- res$sim0
  nyear <- res$nyear
  lag <- res$lag
  future.vpa1 <- get(res$future.function.name)
  fm <- res$fm
  w.recent <- res$w.recent
    
  nY <- nyear
  eyear <- res$eyear
  SRdata <- res$SRdata
  
  seed <- res$seed
  
  B.cur <- SRdata$SSB[length(SRdata$SSB)]
  
  # alpha & abc calculation
    
  target.func <- res$target.func
  
  targ <- res$TARres
    
  Nlast <- targ$naa
  error.last <- targ$eaa+w.recent
  
  Dim.targ <- dim(Nlast)
  
  if (lag == 0) Blast <- NULL else Blast <- targ$ssb[,Dim.targ[2]-(lag-1),]
  
  targ.calc <- function(x) colSums(target.func(Fmsy,farg,mY=mY,eyear=1,seed=seed,N=N,naa0=Nlast[,Dim.targ[2],],eaa0=error.last[Dim.targ[2],],ssb0=Blast,beta=x,delta=0,Blim=Blim,Bban=Bban)$ssb[,1,])
  
  if (beta.est){   
    beta.f1 <- function(x) {
        ssb.tmp <- targ.calc(x)
        Prob1 <- mean(ssb.tmp > Btar)
        x1 <- Prob1-prob.beta[1]
        dist1 <- x1^2
        dist1
    }

    beta.f2 <- function(x) {
        ssb.tmp <- targ.calc(x)
        Prob2 <- mean(ssb.tmp > Blim)

        x2 <- Prob2-prob.beta[2]
        dist1 <- x2^2
        dist1
    }            
    
    res.beta1 <- optimize(beta.f1,beta.range)
    res.beta2 <- optimize(beta.f2,beta.range) 

    beta <- min(res.beta1$minimum,res.beta2$minimum)
#    beta <- floor(beta * 100)/100
  }

  ## �O���t�ɂ��}��
#  ssb.msy <- apply(targ$ssb,c(2,3),sum)[5,]
#  plot(density(ssb.msy),type="l",title="SSB")
#  abline(v=Blim,lty=2,col=2)
#  abline(v=Btar,lty=2)
#  mean(ssb.msy>Blim)
#  mean(ssb.msy>Btar)  

  ssb.tmp <- targ.calc(beta)
  Prob.b1 <- mean(ssb.tmp > Btar)
  Prob.b2 <- mean(ssb.tmp > Blim)
  cat("beta=",round(beta,2),"; Prob SSB>Btar=",Prob.b1, "; Prob SSB>Blim=",Prob.b2,"; \n")  
  
  out <- list(beta=beta)
  
  invisible(list(out,future.pred))
}


calc.beta2 <- function(MSY.input, # Fmsy�iFtarget�j�ŋ��l����悤�ȏ����\���̈���
                       mY=5,prob.beta=c(0.5,0.9),beta=1,delta=1,
                       beta.est=TRUE,beta.range=c(0,1),
                       Btar=res$Btar, # �e��Ǘ���l�͊O����^����
                       Blim=res$Blim,
                       Bban=res$Bban,
                       Fmsy=res$Fmsy)
{
  stockid <- res$stockid
  farg <- res$farg
  N <- res$N
  GT <- res$GT
  sim0 <- res$sim0
  nyear <- res$nyear
  lag <- res$lag
  future.vpa1 <- get(res$future.function.name)
  fm <- res$fm
  w.recent <- res$w.recent
    
  nY <- nyear
  eyear <- res$eyear
  SRdata <- res$SRdata
  
  seed <- res$seed
  
  B.cur <- SRdata$SSB[length(SRdata$SSB)]
  
  # alpha & abc calculation
    
  target.func <- res$target.func
  
  targ <- res$TARres
    
  Nlast <- targ$naa
  error.last <- targ$eaa+w.recent
  
  Dim.targ <- dim(Nlast)
  
  if (lag == 0) Blast <- NULL else Blast <- targ$ssb[,Dim.targ[2]-(lag-1),]
  
  targ.calc <- function(x) colSums(target.func(Fmsy,farg,mY=mY,eyear=1,seed=seed,N=N,naa0=Nlast[,Dim.targ[2],],eaa0=error.last[Dim.targ[2],],ssb0=Blast,beta=x,delta=0,Blim=Blim,Bban=Bban)$ssb[,1,])
  
  if (beta.est){   
    beta.f1 <- function(x) {
        ssb.tmp <- targ.calc(x)
        Prob1 <- mean(ssb.tmp > Btar)
        x1 <- Prob1-prob.beta[1]
        dist1 <- x1^2
        dist1
    }

    beta.f2 <- function(x) {
        ssb.tmp <- targ.calc(x)
        Prob2 <- mean(ssb.tmp > Blim)

        x2 <- Prob2-prob.beta[2]
        dist1 <- x2^2
        dist1
    }            
    
    res.beta1 <- optimize(beta.f1,beta.range)
    res.beta2 <- optimize(beta.f2,beta.range) 

    beta <- min(res.beta1$minimum,res.beta2$minimum)
#    beta <- floor(beta * 100)/100
  }

  ## �O���t�ɂ��}��
#  ssb.msy <- apply(targ$ssb,c(2,3),sum)[5,]
#  plot(density(ssb.msy),type="l",title="SSB")
#  abline(v=Blim,lty=2,col=2)
#  abline(v=Btar,lty=2)
#  mean(ssb.msy>Blim)
#  mean(ssb.msy>Btar)  

  ssb.tmp <- targ.calc(beta)
  Prob.b1 <- mean(ssb.tmp > Btar)
  Prob.b2 <- mean(ssb.tmp > Blim)
  cat("beta=",round(beta,2),"; Prob SSB>Btar=",Prob.b1, "; Prob SSB>Blim=",Prob.b2,"; \n")  
  
  out <- list(beta=beta)
  
  invisible(list(out,future.pred))
}

#############################�@�����܂�

### dynamics MSY���v�Z���Ă݂�                                                                                  
dyn.msy <- function(naa.past,naa.init=NULL,fmsy,a,b,resid,resid.year,waa,maa,M,SR=TRUE){
    nyear <- length(resid)
    if(is.null(naa.init)) nage <- nrow(naa.past) else nage <- length(naa.init)
    naa <- matrix(0,nage,nyear)
    ssb <- numeric()
    if(is.null(naa.init)) naa[,1] <- naa.past[,colnames(naa.past)==min(resid.year)]
    else naa[,1] <- naa.init
    colnames(naa) <- resid.year
    if(is.null(naa.init)){
        waa <- waa[,colnames(naa.past)%in%resid.year]
        maa <- maa[,colnames(naa.past)%in%resid.year]
        M <- M[,colnames(naa.past)%in%resid.year]
    }
    for(i in 2:nyear){
        ssb[i-1] <- sum(naa[,i-1]*waa[,i-1]*maa[,i-1],na.rm=T)
        if(SR==TRUE){
            naa[1,i] <- HS(ssb[i-1],a,b)*exp(resid[i])
        }
        else{
            naa[1,i] <- naa.past[1,i]
            }
        for(j in 2:(nage-1)) naa[j,i] <- naa[j-1,i-1] * exp(-fmsy[j-1]-M[j-1,i-1])
        naa[nage,i] <- naa[nage-1,i-1] * exp(-fmsy[j-1]-M[j-1,i-1]) + naa[nage,i-1] * exp(-fmsy[nage]-M[nage,i-1])
    }
    i <- nyear ; ssb[i] <- sum(naa[,i]*waa[,i]*maa[,i])
    list(naa=naa,ssb=ssb)
}


plot.HCR <- function(beta=1,bban=0,blimit=1,btarget=2,add=FALSE,yscale=1.3,xlim=NULL,
                     Fmsy=1,scale=1,
                     ssb.cur=NULL,...) {
    if(is.null(xlim)) xlim <- c(0,max(c(bban,balimit,btarget)))/scale
    b.tmp <- seq(from=0,to=max(xlim),length=300)
    y <- (b.tmp-bban)/(blimit-bban)*beta
    y <- ifelse(b.tmp>blimit,beta,y)
    y <- ifelse(y<0,0,y)
    if(!isTRUE(add)) plot(b.tmp/scale,Fmsy*y,type="n",ylim=c(0,yscale),xlab="SSB",ylab="multiplier to current F",xlim=xlim/scale)
    points(b.tmp/scale,Fmsy*y,type="l",...)
    abline(h=Fmsy,col="gray")
    text(0,Fmsy+0.02,paste("Fmsy=",round(Fmsy,2),"Fcurrent"),adj=0)
    text(0,Fmsy*beta+0.02,paste("Ftarget=",round(beta*Fmsy,2),"Fcurrent (",round(beta,2),"*Fmsy)",sep=""),adj=0)    

    if(!is.null(ssb.cur)){
        Frec <- (ssb.cur-bban)/(blimit-bban)
        Frec <- ifelse(Frec<0,0,Frec)
        Frec <- ifelse(Frec>1,1,Frec)
        lines(c(0,ssb.cur/scale,ssb.cur/scale),c(Frec*beta*Fmsy,Frec*beta*Fmsy,0),lty=2)
#        points(ssb.cur/scale,Frec*beta*Fmsy,lty=2,pch=4)
#        text(0,0.8*beta*Fmsy+0.02,
#             paste("F2018=",round(Frec*beta*Fmsy,2),"","Fcurrent (",
#                   round(Frec,2),"*",round(beta,2),"*",round(Fmsy,2),"*Fcurrent)",sep=""),adj=0)    
    }
}

draw.refline <- function(reftable,horiz=TRUE,scale=1000,lwd=3){
    if(horiz==FALSE){
        abline(v=reftable[1:4,2]/scale,
               col=c("darkgreen","darkblue","darkred","red"),lwd=lwd,lty="22")
        abline(v=reftable[1:4,1]/scale,
               col=c("darkgreen","darkblue","darkred","red"),lwd=lwd,lty=1)
    }
    else{
        abline(h=reftable[1:4,2]/scale,
               col=c("darkgreen","darkblue","darkred","red"),lwd=lwd,lty="22")
        abline(h=reftable[1:4,1]/scale,
               col=c("darkgreen","darkblue","darkred","red"),lwd=lwd,lty=1)
        }
}

