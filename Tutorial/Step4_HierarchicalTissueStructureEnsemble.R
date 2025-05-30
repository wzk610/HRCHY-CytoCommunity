library(diceR)

# Hyperparameters
Num_Run = 20
Num_Cell = 6667
Num_Fine = 15
Num_Coarse = 2

#Import data.
NodeMask <- read.csv("Run1/NodeMask.csv", header = FALSE)
nonzero_ind <- which(NodeMask$V1 == 1)

#Find the file names of all soft clustering results.
allSoftClustFile1 <- list.files(path = "./", pattern = "ClusterAssignMatrix_Fine.csv", recursive = TRUE)
allSoftClustFile2 <- list.files(path = "./", pattern = "ClusterAssignMatrix_Coarse.csv", recursive = TRUE)
allHardClustLabel1 <- vector()
allHardClustLabel2 <- vector()
allcoarse <- vector()

HardMatrix <- matrix(data = NA, nrow=Num_Cell)
CoarseMatrix <- matrix(data = NA, nrow=Num_Fine)

for (i in 1:length(allSoftClustFile1)) {
  
  ClustMatrix1 <- read.csv(allSoftClustFile1[i], header = FALSE, sep = ",")
  ClustMatrix1 <- ClustMatrix1[nonzero_ind,]
  ClustMatrix2 <- read.csv(allSoftClustFile2[i], header = FALSE, sep = ",")
  ClustMatrix2 <- as.matrix(ClustMatrix1) %*% as.matrix(ClustMatrix2)
  HardClustLabel1 <- apply(as.matrix(ClustMatrix1), 1, which.max)
  HardClustLabel2 <- apply(as.matrix(ClustMatrix2), 1, which.max)
  HardMatrix <- cbind(HardMatrix, HardClustLabel1)
  HardMatrix <- cbind(HardMatrix, HardClustLabel2)
  rm(ClustMatrix1)
  rm(ClustMatrix2)
  
  allHardClustLabel1 <- cbind(allHardClustLabel1, as.vector(HardClustLabel1))
  
}


finalClass1 <- diceR::majority_voting(allHardClustLabel1, is.relabelled = FALSE)
HardMatrix <- HardMatrix[, -1]
HardMatrix <- cbind(HardMatrix, finalClass1)

for (i in 1:Num_Run) {
  for(j in 1:Num_Fine){
    subset_matrix <- subset(HardMatrix, HardMatrix[, Num_Run*2+1] == j)
    CoarseMatrix[j,1] <- names(sort(table(subset_matrix[, 2*i]), decreasing = TRUE)[1])
  }
  allcoarse <- cbind(allcoarse, as.vector(CoarseMatrix))
}

final_finetocoarse <- diceR::majority_voting(allcoarse, is.relabelled = FALSE)

finalmatrix <- as.matrix(finalClass1)
trans <- as.matrix(final_finetocoarse)
for (i in 1:Num_Coarse){
  finalmatrix[finalmatrix == i] = Num_Fine+i
}
for (i in (Num_Coarse+1):Num_Fine){
  finalmatrix[finalmatrix == i] = trans[i,1]
}
for (i in 1:Num_Coarse){
  finalmatrix[finalmatrix == Num_Fine+i] = trans[i,1]
}
finalClass2 = finalmatrix

write.table(finalClass1, file = "ConsensusLabel_MajorityVoting_Fine.csv", append = FALSE, quote = FALSE, row.names = FALSE, col.names = FALSE)
write.table(finalClass2, file = "ConsensusLabel_MajorityVoting_Coarse.csv", append = FALSE, quote = FALSE, row.names = FALSE, col.names = FALSE)


