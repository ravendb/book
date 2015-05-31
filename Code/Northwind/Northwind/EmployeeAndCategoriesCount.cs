// -----------------------------------------------------------------------
//  <copyright file="EmployeeAndCategoriesCount.cs" company="Hibernating Rhinos LTD">
//      Copyright (c) Hibernating Rhinos LTD. All rights reserved.
//  </copyright>
// -----------------------------------------------------------------------

using System.Linq;
using Orders;
using Raven.Client.Indexes;

namespace Northwind
{
public class EmployeeAndCategoriesCount : AbstractMultiMapIndexCreationTask<EmployeeAndCategoriesCount.Result>
{
	public class Result
	{
		public int Categories;
		public int Employees;
	}

	public EmployeeAndCategoriesCount()
	{
		AddMap<Employee>(employees =>
			from employee in employees
			select new
			{
				Employees = 1,
				Categories = 0
			}
		);
		AddMap<Category>(categories =>
			from category in categories
			select new
			{
				Employees = 0,
				Categories = 1
			}
		);

		Reduce = results =>
			from result in results
			group result by "const"
			into g
			select new
			{
				Employees = g.Sum(x => x.Employees),
				Categories = g.Sum(x => x.Categories)
			};
	}
}
}