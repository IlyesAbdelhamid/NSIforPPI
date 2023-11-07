# Network shape intelligence outperforms AlphaFold2 intelligence in vanilla protein interaction prediction

## Reference 
https://www.biorxiv.org/content/10.1101/2023.08.10.552825v2

Ilyes Abdelhamid1,5,†, Alessandro Muscoloni1,4,5,†, Danny Marc Rotscher6, Matthias Lieber6, Ulf Markwardt6 and Carlo Vittorio Cannistraci1,2,3,4,5*.

## Affiliations
1. Center for Complex Network Intelligence (CCNI), Tsinghua Laboratory of Brain and Intelligence (THBI), Tsinghua University, Beijing, China.
2. Department of Computer Science, Tsinghua University, Beijing, China.
3. Department of Physics, Tsinghua University, Beijing, China.
4. Department of Biomedical Engineering, Tsinghua University, Beijing, China.
5. Biomedical Cybernetics Group, Biotechnology Center (BIOTEC), Center for Molecular and Cellular Bioengineering (CMCB), Department of Physics, Technische Universität Dresden, Dresden, Germany. 
6. Center for Information Services and High-Performance Computing (ZIH), Technische Universität Dresden, Dresden, Germany.  
  
† First co-authorship  
*Corresponding author: Carlo Vittorio Cannistraci (kalokagathos.agon@gmail.com) 

## Abstract
<p align="justify"> For decades, scientists and engineers have been working to predict protein interactions, and network topology methods have emerged as extensively studied techniques. Recently, approaches based on AlphaFold2 intelligence, exploiting 3D molecular structural information, have been proposed for protein interaction prediction, they are promising as potential alternatives to traditional laboratory experiments, and their design and performance evaluation is compelling. 
Here, we introduce a new concept of intelligence termed Network Shape Intelligence (NSI). NSI is modelled via network automata rules which minimize external links in local communities according to a brain-inspired principle, as it draws upon the local topology and plasticity rationales initially devised in brain network science and then extended to any complex network. We show that by using only local network information and without the need for training, these network automata designed for modelling and predicting network connectivity can outperform AlphaFold2 intelligence in vanilla protein interactions prediction. We find that the set of interactions mispredicted by AlphaFold2 predominantly consists of proteins whose amino acids exhibit higher probability of being associated with intrinsically disordered regions. Finally, we suggest that the future advancements in AlphaFold intelligence could integrate principles of NSI to further enhance the modelling and structural prediction of protein interactions.</p>

## Folders description
```git clone``` the NSIforPPI repository. Every item folder (except **Suppl AFM**) is organized as follows:
+ **data**  
  It contains a word document with a link to download the data. Extract the content of the downloaded data in this folder. 
+ **data_replicated**  
  It contains the scripts to generate the item from the original data, involving all the required computations. Outcomes of these computations are stored in the different subfolders already created.
+ **README_***  
  A README file that explains how to generate/replicate the item.
+ **run_*.m**.  
  The main code with two options:
  - Option 1: generate item with existing results.
  - Option 2: to recreate item from original data.
