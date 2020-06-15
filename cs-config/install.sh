# bash commands for installing your package
git clone https://github.com/burkeob/COVID-MCS
cd COVID-MCS
conda install -c conda-forge paramtools pandas rpy2
conda install -c r r r-dplyr r-lubridate
conda install -c conda-forge r-quadprog libopenblas

pip install -e .
