	/*******************************************************************************
* File Name: CreateFigures
* 
* Principal investigators: James Stock and Gilbert Metcalf
* Compiled by: Gib Metcalf 
*
* Last revised: Feb 25, 2022
*
* Description: Constructs figures [and tables?] for the Metcalf Stock AEJ:M paper
*
*  All figures are stored in folder results/figures 
********************************************************************************/

clear all

*** SET DIRECTORY HERE:
cd "C:\Users\matti\OneDrive\Desktop\uni\thesis\5. Mattia fa cose\do-files\02_analysis" 

*
capture log using CreateFigures.log , replace
set scheme s1color
global figtype "png"
*******************************************************************************
*		 Run program to construct data plots
*******************************************************************************
do EUctax_figures_1
******************************************************************************
*	Next construct IRFs and CIRFs
******************************************************************************
do EUctax_figures_2
******************************************************************************
*	Figure A4 requires data from the previous run.  Create figure A4 now
******************************************************************************
do EUctax_figures_2a
******************************************************************************
*	Nonlinear IRF Figures A16 - A24
******************************************************************************
do Euctax_figures_3

log close
