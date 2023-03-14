/* QUESTION 1 */
/* Part 1: fixed allocations in asset classes*/

filename data "~/datafiles/Asset Returns 2000-2017.xlsx";

proc import dbms = XLSX replace datafile = data
    out = Returns; sheet = "Returns 2000-2017";
run;

proc import dbms = XLSX replace datafile = data
    out = Assets; sheet = "Assets";
run;

proc import dbms = XLSX replace datafile = data
    out = Correlations; sheet = "Correlations";
run;


proc optmodel;

set <str> Assets;

set Q1_all_assets = {'Russell_1000',
					 'Russell_2000_Value', 
					 'Russell_2000_Growth',
					 'Barclays_US_Bonds',
					 'Barclays_IG_Bonds'};

num Q1_given_allocations{Q1_all_assets} = [.3 .15 .15 .2 .2];

num Mean_return{Assets};
num Stdev{Assets};
num correlation{assets, assets};

read data Assets into Assets = [Asset] Mean_return stdev=Stdev_return;
read data Correlations into [Asset] {j in assets} <correlation[asset,j]=col(j)>;

num portfolio_return=sum{i in Q1_all_assets} Q1_given_allocations[i]*mean_return[i];

num portfolio_variance=sum {i in Q1_all_assets, j in Q1_all_assets} 
					   Q1_given_allocations[i]*Q1_given_allocations[j]*stdev[i]*stdev[j]*correlation[i,j];
					   
num portfolio_stdev = sqrt(portfolio_variance);

min variance = portfolio_variance;
solve with lp;

print portfolio_return portfolio_stdev;
print mean_return stdev Q1_given_allocations;

quit;



/* Part 2: fixed average return, 60/40 split between stocks and bonds */

filename data "~/datafiles/Asset Returns 2000-2017.xlsx";

proc import dbms = XLSX replace datafile = data
    out = Returns; sheet = "Returns 2000-2017";
run;

proc import dbms = XLSX replace datafile = data
    out = Assets; sheet = "Assets";
run;

proc import dbms = XLSX replace datafile = data
    out = Correlations; sheet = "Correlations";
run;

proc optmodel;

set <str> Assets;

set stocks_Q1 = {'Russell_1000','Russell_2000_Value', 'Russell_2000_Growth'};
set bonds_Q1 = {'Barclays_US_Bonds','Barclays_IG_Bonds'};
set Q1_all_assets = {'Russell_1000','Russell_2000_Value', 'Russell_2000_Growth','Barclays_US_Bonds','Barclays_IG_Bonds'};

num Mean_return{Assets};
num Stdev{Assets};
num correlation{assets, assets};

read data Assets into Assets = [Asset] Mean_return stdev=Stdev_return;
read data Correlations into [Asset] {j in assets} <correlation[asset,j]=col(j)>;

var allocation{Q1_all_assets} >= 0; 

impvar portfolio_return=sum {i in Q1_all_assets} allocation[i]*mean_return[i];
impvar portfolio_variance=sum {i in Q1_all_assets, j in Q1_all_assets} allocation[i]*allocation[j]*stdev[i]*stdev[j]*correlation[i,j];
impvar portfolio_stdev = sqrt(portfolio_variance);

con allocate_assets: sum{i in Q1_all_assets} allocation[i]=1;
con required_return: portfolio_return = 6.8698;

/* commenting out when dropping 60/40 split constraint */
con stock_split: sum{i in stocks_Q1} allocation[i] = .6;
con bond_split: sum{i in bonds_Q1} allocation[i] = .4;

min variance = portfolio_variance;

solve with nlp/algorithm=activeset;

print portfolio_return portfolio_stdev;
print allocation;

quit;

