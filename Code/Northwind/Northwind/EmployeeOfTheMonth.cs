// -----------------------------------------------------------------------
//  <copyright file="EmployeeOfTheMonth.cs" company="Hibernating Rhinos LTD">
//      Copyright (c) Hibernating Rhinos LTD. All rights reserved.
//  </copyright>
// -----------------------------------------------------------------------

using System;
using System.Linq;
using Orders;
using Raven.Abstractions.Indexing;
using Raven.Client.Indexes;

namespace Northwind
{
public class EmployeeOfTheMonth : AbstractIndexCreationTask<Order, EmployeeOfTheMonth.Result>
{
	public class Result
	{
		public string Employee;
		public string Month;
		public int TotalSales;
	}

	public EmployeeOfTheMonth()
	{
		Map = orders =>
			from order in orders
			select new
			{
				order.Employee,
				Month = order.OrderedAt.ToString("yyyy-MM"),
				TotalSales = 1
			};

		Reduce = results =>
			from result in results
			group result by new {result.Employee, result.Month}
			into g
			select new
			{
				g.Key.Employee,
				g.Key.Month,
				TotalSales = g.Sum(x => x.TotalSales)
			};
		Sort(x => x.TotalSales, SortOptions.Int);
	}
}
}