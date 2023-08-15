## Cluster settings

<details>
<summary>Click to expand</summary>

```
# create .Rprofile
cat ~/.Rprofile
# options(repos = c(CRAN = "https://mirrors.nics.utk.edu/cran"))

# create .Renviron
cat ~/.Renviron 
# R_LIBS_USER=~/R/%p/%v

# create R folders
cd
mkdir -p R
mkdir -p R/x86_64-pc-linux-gnu
mkdir -p R/x86_64-pc-linux-gnu/4.2

# set cpp 17 variables
mkdir -p ~/.R
cat ~/.R/Makevars
# echo "CC = $(which gcc) -fPIC"
# echo "CXX17 = $(which g++) -fPIC"
# echo "CXX17STD = -std=c++17"
# echo "CXX17FLAGS = ${CXX11FLAGS}"
```

</details>

<br><br>

