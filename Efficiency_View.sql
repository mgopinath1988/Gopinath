

WITH Efficiency_Budget AS 
	(SELECT E.PU, E.FamilyName, E.Earned_Hours, E.Production_Hours, E.NonProduction_Hours, E.Efficiency,
			G.Goal_Efficiency As Efficiency_Goal_Budget, E.Efficiency - G.Goal_Efficiency AS Delta_Efficiency_Budget,
			E.Utilization, G.Goal_Utilization AS Utilization_Goal_Budget, E.Efficiency - E.Utilization AS GAP, 
			E.Update_Date
	FROM [HRD].[Efficiency_Report] AS E 
INNER JOIN HRD.Efficiency_Goals AS G ON E.FamilyName = G.Core_TEAM
AND (Phase = 'Budget')
AND (G.[Year] = YEAR(GETDATE())) 
AND (G.[Month] = MONTH(GETDATE())))


SELECT 
	E.PU, E.FamilyName, E.Earned_Hours, E.Production_Hours, E.NonProduction_Hours, E.Efficiency,
	E.Efficiency_Goal_Budget, E.Delta_Efficiency_Budget, E.Utilization,  E.Utilization_Goal_Budget, E.GAP, 
	G.[Goal_Efficiency] AS Efficiency_Goal_Forecast, E.Efficiency - G.[Goal_Efficiency] AS Delta_Efficiency_Forecast,
	G.[Goal_Utilization]  AS Utilization_Goal_Forecast, E.Utilization - G.[Goal_Utilization] AS Delta_Utilization_Forecast, 
	E.Utilization_Goal_Budget *  E.Production_Hours as Theorical_EH,
	E.Earned_Hours - (E.Utilization_Goal_Budget * (E.Production_Hours + E.NonProduction_Hours)) as EH_Delta,
	(E.Earned_Hours - (E.Utilization_Goal_Budget * (E.Production_Hours + E.NonProduction_Hours))) * LR.Labor_Rate as Impact,
	LR.Labor_Rate, E.Update_Date
	FROM Efficiency_Budget AS E 
INNER JOIN [HRD].[Efficiency_Goals] AS G ON E.FamilyName = G.Core_TEAM
INNER JOIN [HRD].[Efficiency_Labor_Rates] AS LR ON  E.FamilyName = LR.FamilyName
AND (Phase = (SELECT TOP 1 [Phase] FROM [HRD].[Efficiency_Goals] ORDER BY Goal_ID DESC))
AND (G.[Year] = YEAR(GETDATE())) 
AND (G.[Month] = MONTH(GETDATE()))
AND (LR.[Year] = YEAR(GETDATE()))

UNION

SELECT A.PU, 'Total' AS Family, SUM(A.Earned_Hours) AS Earned_Hours, SUM(A.Production_Hours) AS Production_Hours, 
SUM(A.NonProduction_Hours) AS NonProduction_Hours, 
ISNULL(SUM(A.Earned_Hours)/NULLIF (SUM(A.Production_Hours), 0), 0) AS Efficiency,
		(SELECT Goal_Efficiency
         FROM   HRD.Efficiency_Goals
         WHERE  (Core_Team = A.PU) AND (Phase = 'Budget') AND ([Year] = YEAR(GETDATE())) AND ([Month] = MONTH(GETDATE()))) 
         AS Efficiency_Goal_Budget, 

		ISNULL(SUM(A.Earned_Hours)/ NULLIF(SUM(A.Production_Hours),0),0) -  
		 (SELECT Goal_Efficiency
         FROM   HRD.Efficiency_Goals
		 WHERE  (Core_Team = A.PU) AND (Phase = 'Budget')  AND ([Year] = YEAR(GETDATE())) AND ([Month] = MONTH(GETDATE()))) 
		 AS Delta_Efficiency_Budget, 

         ISNULL( SUM(A.Earned_Hours)/ NULLIF (SUM(A.Production_Hours)+SUM(A.NonProduction_Hours), 0),0) AS Utilization, 

		 (SELECT Goal_Utilization
         FROM   HRD.Efficiency_Goals
         WHERE  (Core_Team = A.PU) AND (Phase = 'Budget')  AND ([Year] = YEAR(GETDATE())) AND ([Month] = MONTH(GETDATE()))) 
         AS Utilization_Goal_Budget, 

		
		 ISNULL(SUM(A.Earned_Hours)/ NULLIF(SUM(A.Production_Hours),0),0) -
		 ISNULL(SUM(A.Earned_Hours)/ NULLIF((SUM(A.Production_Hours)+SUM(A.NonProduction_Hours)),0),0)
		 AS GAP,

		 (SELECT Goal_Efficiency
         FROM   HRD.Efficiency_Goals
         WHERE  (Core_Team = A.PU) AND (Phase = (SELECT TOP 1 Phase FROM HRD.Efficiency_Goals ORDER BY Goal_ID DESC ))  
																AND ([Year] = YEAR(GETDATE())) AND ([Month] = MONTH(GETDATE()))) 
		  AS Efficiency_Goal_Forecast,
		  
		  ISNULL(SUM(A.Earned_Hours)/NULLIF(SUM(A.Production_Hours),0),0) - 
		 (SELECT Goal_Efficiency
         FROM   HRD.Efficiency_Goals
         WHERE  (Core_Team = A.PU) 
		 AND (Phase = (SELECT TOP 1 Phase FROM HRD.Efficiency_Goals
		 ORDER BY Goal_ID DESC ))  AND ([Year] = YEAR(GETDATE())) AND ([Month] = MONTH(GETDATE()))) 
		 AS Delta_Efficiency_Forecast,

		 (SELECT Goal_Utilization
         FROM   HRD.Efficiency_Goals
         WHERE  (Core_Team = A.PU) 
		 AND (Phase = (SELECT TOP 1 Phase FROM HRD.Efficiency_Goals ORDER BY Goal_ID DESC ))  
											AND ([Year] = YEAR(GETDATE())) AND ([Month] = MONTH(GETDATE()))) 
		 AS Utilization_Goal_Forecast,

		 ISNULL( SUM(A.Earned_Hours)/ NULLIF (SUM(A.Production_Hours)+SUM(A.NonProduction_Hours), 0),0)  -
		 (SELECT Goal_Utilization
         FROM   HRD.Efficiency_Goals
         WHERE  (Core_Team = A.PU) 
		 AND (Phase = (SELECT TOP 1 Phase FROM HRD.Efficiency_Goals ORDER BY Goal_ID DESC ))
												AND ([Year] = YEAR(GETDATE())) AND ([Month] = MONTH(GETDATE()))) 
		 AS Delta_Utilization_Forecast,
		 NULL AS Theorical_EH,
		 NULL AS EH_Delta,
		 SUM((A.Earned_Hours - (G.Goal_Utilization * (A.Production_Hours + A.NonProduction_Hours))) * LR.Labor_Rate) as Impact,
		 null AS Labor_Rate,
		 Max(A.Update_Date)

FROM  HRD.Efficiency_Report as A
	  INNER JOIN HRD.Efficiency_Labor_Rates AS LR ON  A.FamilyName = LR.FamilyName
	  INNER JOIN HRD.Efficiency_Goals AS G ON A.FamilyName = G.Core_TEAM
	  AND (Phase = 'Budget')
	  AND (G.[Year] = YEAR(GETDATE())) 
	  AND (G.[Month] = MONTH(GETDATE()))
GROUP BY A.PU

UNION

SELECT 'Total Site' AS PU, ' ' as Core_Team, SUM(A.Earned_Hours) AS Earned_Hours, SUM(A.Production_Hours) AS Production_Hours, 
SUM(A.NonProduction_Hours) AS NonProduction_Hours, 
ISNULL(SUM(A.Earned_Hours)/ NULLIF(SUM(A.Production_Hours),0),0) AS Efficiency,
		(SELECT Goal_Efficiency
         FROM   HRD.Efficiency_Goals
         WHERE  (Core_Team = 'Total Site') AND (Phase = 'Budget')  AND ([Year] = YEAR(GETDATE())) AND ([Month] = MONTH(GETDATE()))) 
         AS Efficiency_Goal_Budget, 

		ISNULL(SUM(A.Earned_Hours)/ NULLIF(SUM(A.Production_Hours),0),0) -  
		 (SELECT Goal_Efficiency
         FROM   HRD.Efficiency_Goals
         WHERE  (Core_Team = 'Total Site') AND (Phase = 'Budget')  AND ([Year] = YEAR(GETDATE())) AND ([Month] = MONTH(GETDATE()))) 
		 AS Delta_Efficiency_Budget, 

         ISNULL(SUM(A.Earned_Hours)/NULLIF(((SUM(A.Production_Hours)+SUM(A.NonProduction_Hours))),0),0) AS Utilization, 

		 (SELECT Goal_Utilization
         FROM   HRD.Efficiency_Goals
         WHERE  (Core_Team = 'Total Site') AND (Phase = 'Budget')  AND ([Year] = YEAR(GETDATE())) AND ([Month] = MONTH(GETDATE()))) 
         AS Utilization_Goal_Budget, 

		 ISNULL(SUM(A.Earned_Hours)/NULLIF(SUM(A.Production_Hours),0),0)-
		 ISNULL(SUM(A.Earned_Hours)/NULLIF((SUM(A.Production_Hours)+SUM(A.NonProduction_Hours)),0),0)
		  AS GAP,

		 (SELECT Goal_Efficiency
         FROM   HRD.Efficiency_Goals
         WHERE  (Core_Team = 'Total Site') 
		 AND (Phase = (SELECT TOP 1 Phase FROM HRD.Efficiency_Goals ORDER BY Goal_ID DESC ))  AND ([Year] = YEAR(GETDATE())) AND ([Month] = MONTH(GETDATE()))) 	
		  AS Efficiency_Goal_Forecast,

		 ISNULL(SUM(A.Earned_Hours)/NULLIF(SUM(A.Production_Hours),0),0) - 
		 (SELECT Goal_Efficiency
         FROM  HRD.Efficiency_Goals
         WHERE  (Core_Team = 'Total Site') 
		 AND (Phase = (SELECT TOP 1 Phase FROM HRD.Efficiency_Goals ORDER BY Goal_ID DESC ))  AND ([Year] = YEAR(GETDATE())) AND ([Month] = MONTH(GETDATE()))) 
		 AS Delta_Efficiency_Forecast,

		 ISNULL((SELECT Goal_Utilization
         FROM   HRD.Efficiency_Goals
         WHERE  (Core_Team = 'Total Site') AND (Phase = (SELECT TOP 1 Phase FROM HRD.Efficiency_Goals ORDER BY Goal_ID DESC ))  AND ([Year] = YEAR(GETDATE())) AND ([Month] = MONTH(GETDATE()))) , 0)	
		 AS Utilization_Goal_Forecast,

		 ISNULL(SUM(A.Earned_Hours)/NULLIF(SUM(A.Production_Hours)+SUM(A.NonProduction_Hours), 0),0) -
		 (SELECT Goal_Utilization
         FROM   HRD.Efficiency_Goals
         WHERE  (Core_Team = 'Total Site') AND (Phase = (SELECT TOP 1 Phase FROM HRD.Efficiency_Goals ORDER BY Goal_ID DESC ))
		  AND ([Year] = YEAR(GETDATE())) AND ([Month] = MONTH(GETDATE()))) 
		 AS Delta_Utilization_Forecast,
		 NULL AS Theorical_EH,
		 NULL AS EH_Delta,
		 SUM((A.Earned_Hours - (G.Goal_Utilization * (A.Production_Hours+A.NonProduction_Hours))) * LR.Labor_Rate) as Impact,
		 null AS Labor_Rate,
		  Max(A.Update_Date)

FROM  HRD.Efficiency_Report as A
	  INNER JOIN HRD.Efficiency_Labor_Rates AS LR ON  A.FamilyName = LR.FamilyName
	  INNER JOIN HRD.Efficiency_Goals AS G ON A.FamilyName = G.Core_TEAM
	  AND (Phase = 'Budget')
	  AND (G.[Year] = YEAR(GETDATE())) 
	  AND (G.[Month] = MONTH(GETDATE()))


GO








--Select * FROM   HRD.Efficiency_Goals


--Select * FROM  HRD.Efficiency_Labor_Rates

--Select * FROM   HRD.Efficiency_Report