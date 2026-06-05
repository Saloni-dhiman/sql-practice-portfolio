SELECT * 
FROM layoffs_staging2;

-- lets explore the data by looking at specific company, loaction, industry, country and date to get some insights 
SELECT MAX(total_laid_off) , MAX(percentage_laid_off)
FROM layoffs_staging2; 

SELECT * 
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

SELECT * 
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- amazon and google are at the top companies having maximum of total laid off
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY SUM(total_laid_off) DESC ;

-- here us and india are on top in terms of total laid off
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY SUM(total_laid_off) DESC ;

-- here us and india are top in trms of funds raised 
SELECT country, SUM(funds_raised_millions)
FROM layoffs_staging2
GROUP BY country
ORDER BY SUM(funds_raised_millions) DESC ;

-- in terms of timeline 
SELECT `date`, MAX(total_laid_off),MAX(funds_raised_millions)
FROM layoffs_staging2
GROUP BY `date`;

-- so this layoff started in year 2020 till 2023
SELECT MAX(`date`),MIN(`date`)
FROM layoffs_staging2;

-- if we see which year had the most layoffs then in 2022 we faced max layoffs and in 2021 there were least layoffs
SELECT YEAR(`date`), MAX(total_laid_off),MAX(funds_raised_millions)
FROM layoffs_staging2
GROUP BY YEAR(`date`);

SELECT YEAR(`date`), SUM(total_laid_off),SUM(funds_raised_millions)
FROM layoffs_staging2
GROUP BY YEAR(`date`);

-- let's see which industry impacted the most - WE get consumer and retail industry impacted the most
SELECT industry, MAX(total_laid_off),MAX(funds_raised_millions),SUM(total_laid_off),SUM(funds_raised_millions)
FROM layoffs_staging2
GROUP BY industry
ORDER BY MAX(total_laid_off) DESC,MAX(funds_raised_millions) DESC,SUM(total_laid_off) DESC,SUM(funds_raised_millions) DESC;

-- in thia POST IPO and acquired are at the top in terms of stage 
SELECT stage, MAX(total_laid_off),MAX(funds_raised_millions),SUM(total_laid_off),SUM(funds_raised_millions)
FROM layoffs_staging2
GROUP BY stage
ORDER BY MAX(total_laid_off) DESC,MAX(funds_raised_millions) DESC,SUM(total_laid_off) DESC,SUM(funds_raised_millions) DESC; 

-- in this service and airy room are at the top 
SELECT company ,SUM(percentage_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY SUM(percentage_laid_off) DESC;

SELECT country ,SUM(percentage_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY SUM(percentage_laid_off) DESC;

-- to take results according to months we need to create a substring for months
SELECT SUBSTRING(`date`,6,2) AS `Month`,SUM(percentage_laid_off) ,MAX(percentage_laid_off) ,MAX(total_laid_off),MAX(funds_raised_millions),
SUM(total_laid_off),SUM(funds_raised_millions)
FROM layoffs_staging2
GROUP BY `Month`
ORDER BY `Month` DESC ;

SELECT SUBSTRING(`date`,1,7) AS `Month`,SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `Month`
ORDER BY 1 ;

-- Creating a rolling total
WITH Rolling_total AS
(
SELECT SUBSTRING(`date`,1,7) AS `Month`,SUM(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `Month`
ORDER BY 1 
)
SELECT `Month`, total_off, SUM(total_off) OVER( ORDER BY `Month`) AS rolling_total
FROM Rolling_total;

-- in this we are going to filter out top 5 companies in each year who did the most laid offs by ranking them
WITH company_year (company,years,total_off)AS 
(
SELECT company, YEAR (`date`),SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR (`date`)
),
company_years_ramk AS
(
SELECT *,
DENSE_RANK() OVER(PARTITION BY years ORDER BY total_off DESC) AS ranking
FROM company_year
WHERE years IS NOT NULL 
)
SELECT * 
FROM company_years_ramk
WHERE ranking <= 5;








