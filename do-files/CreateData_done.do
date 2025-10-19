*******************************************************************************
* File Name: CreateData.do
* 
* Principal investigators: James Stock and Gilbert Metcalf
* Compiled by: Siddhi Doshi and Gib Metcalf 
*
* Last revised: March 4, 2022
*
* Description: Compiles the dataset for the Metcalf Stock AEJ:M paper
* The following variables are created:
*  obs:         1,888                          
* vars:            23                          4 Mar 2022 08:12
*----------------------------------------------------------------------------------
*              storage   display    value
*variable name   type    format     label      variable label
*----------------------------------------------------------------------------------
*country         str66   %66s                  name
*ID              str8    %9s                   LOCATION
*year            int     %10.0g                Year
*EU2             float   %9.0g                 EU plus Iceland, Norway, Switzerland
*IntRevRec       double  %10.0g                Fraction of carbon tax revenues
*                                                initially earmarked for tax
*                                                reduction
*SCA             float   %9.0g                 Norway, Sweden, Denmark, Finland
*ctaxever        float   %9.0g                 carbon tax in any year
*ctaxyear        float   %9.0g                 First year of carbon tax (else
*                                                missing)
*dlemission_ct~s float   %9.0g                 CO2 from fuel consumption in road
*                                                transport, commercial and
*                                                institutional sector
*dlempman        float   %9.0g                 Manufacturing employment annual
*                                                growth rate (percent)
*dlemptot        float   %9.0g                 Total employment annual growth rate
*                                                (percent)
*dlrgdp          float   %9.0g                 Real GDP annual growth rate
*                                                (percent)
*dlrgdppc        float   %9.0g                 Real GDPPC annual growth rate
*                                                (percent)
*ecp_ghg_ta~2018 float   %9.0g                 Emissions (2013 GHG) weighted carbon
*                                                tax, 2018 USD
*emission_ctse~s float   %9.0g                 CO2 from fuel combustion in road
*                                                transport, commercial,
*                                                institutional, household
*lemission_cts~s float   %9.0g                 log(emission_ctsectors)
*lempman         float   %9.0g                 log(manufactoring employment)
*lemptot         float   %9.0g                 log(total employment)
*lrgdp           float   %9.0g                 log real gdp
*lrgdppc         float   %9.0g                 log real per capita gdp
*pgdp            double  %10.0g                GDP deflator, local currency
*rater_LCU_USD18 float   %9.0g                 Carbon tax rate (real, LCU, 2018 USD
*                                                @ PPP)
*share19         float   %9.0g                 share GHG emissions covered by tax
*                                                in 2019
*----------------------------------------------------------------------------------


********************************************************************************/

clear all

**********************************************************************************
* SET DIRECTORY HERE:
*	This should be the same directory that this do file is in 
***********************************************************************************
cd "C:\Users\matti\OneDrive\Desktop\uni\thesis\5. Mattia fa cose\do-files\01_create_dataset" //for windows

capture log using CreateData.log , replace
*******************************************************************************
		* 1. Setting up all the datasets
*******************************************************************************
* INSTALL the following package if not already installed:
 net install tidy, from("https://raw.githubusercontent.com/matthieugomez/tidy.ado/master/") replace
*
************* Names ********************
* This file standardizes the country names in the dataset 
* FINITO, NON TOCCARE
*
include names

************* GDP data ********************
*This file compiles the GDP dataset and makes changes to Norway and Ireland dataset
*  as discussed in the paper.
*
include gdp

************* Carbon tax data ********************
*Compiles carbon tax data from the World Bank's carbon pricing dashboard
*
include ctax

*************  Emissions data ********************
include emisson_2018

*************  Employment data ********************
*Manufacturing and total employment data
include employment

*******************************************************************************
* 2. Merging the datasets and running calculations to create the final dataset 
*	The final dataset is called ctax_AEJM and is found
*	in the folder root/stata/data.
*******************************************************************************
include merge_and_calculate_2018
erase names.dta
log close
