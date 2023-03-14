/* QUESTION 3 */

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

proc optmodel printlevel=0;

set <str> Assets;

set Q3_all_assets = {'Russell_1000',
					 'Russell_2000_Value', 
					 'Russell_2000_Growth',
					 'EAFE_Intl_Index',
					 'Barclays_US_Bonds',
					 'Barclays_IG_Bonds',
					 'Barclays_HY_Bonds',
					 'GSCI_Precious_Metals', 
					 'FTSE_REIT_Index'};

num Mean_return{Assets};
num Stdev{Assets};
num correlation{assets, assets};

read data Assets into Assets = [Asset] Mean_return stdev=Stdev_return;
read data Correlations into [Asset] {j in assets} <correlation[asset,j]=col(j)>;

var allocation{Q3_all_assets} >= 0; 

impvar portfolio_return=sum {i in Q3_all_assets} allocation[i]*mean_return[i];
impvar portfolio_variance=sum {i in Q3_all_assets, j in Q3_all_assets} allocation[i]*allocation[j]*stdev[i]*stdev[j]*correlation[i,j];
impvar portfolio_stdev = sqrt(portfolio_variance);

num initial_return = 4.25;
num req_return init initial_return;

con allocate_assets: sum{i in Q3_all_assets} allocation[i]=1;
con required_return: portfolio_return = req_return;

min variance = portfolio_variance;

solve with nlp/algorithm=activeset;

print portfolio_return portfolio_stdev;
print allocation;

/* Efficient frontier */

set portfolios = 1..28; 
num return {portfolios} = [4.25 4.5 4.75 5 5.25 5.5 5.75 6 6.25 6.5 6.75 7 7.25 7.5 7.75 8 8.25 8.5 8.75 9 9.25 9.5 9.75 10 10.25 10.5 10.75 11]; /* required return values */
num min_var {portfolios};
num min_stdev {portfolios};
num dual_val {portfolios}; 		/* for linear approximation  */
num eff_allocation {portfolios,Q3_all_assets};

for {p in portfolios} do;
	req_return = return[p];
	solve with qp;
	min_var[p] = variance;
	min_stdev[p] = sqrt(variance);
	dual_val[p] = required_return.dual;
	for {j in Q3_all_assets} eff_allocation[p,j] = allocation[j];
end;

num base_case = 5;    			/* base case for linear approximation */
num linear_approx {portfolios}; /* use dual value at base case for linear approx */
for {p in portfolios} linear_approx[p] = min_var[base_case] + dual_val[base_case]*(return[p]-return[base_case]);
	
create data efficient from [eff_port] return min_var min_stdev linear_approx {j in Q3_all_assets} <col(j)=eff_allocation[eff_port,j]>;

print min_stdev return;

PROC SGPLOT DATA = efficient;
series X = min_stdev Y = return/markers smoothconnect;
TITLE 'Efficient Frontier';
YAXIS GRID;
Xaxis max=16;
run;

quit;