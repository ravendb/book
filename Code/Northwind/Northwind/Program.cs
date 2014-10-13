using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Expressions;
using Orders;
using Raven.Abstractions.Replication;
using Raven.Client;
using Raven.Client.Document;
using Raven.Client.Indexes;
using Raven.Client.Linq;

namespace Northwind
{
	internal class Program
	{
		private static DocumentStore _documentStore;

		private static void Main(string[] args)
		{
			_documentStore = new DocumentStore
			{
				Url = "http://localhost:8080",
				DefaultDatabase = "Northwind",
			};

			_documentStore.Initialize();

			while (true)
			{

				using (var session = _documentStore.OpenSession())
				{
					session.Query<Orders_Totals.Result, Orders_Totals>()
						.Where(x => x.Total > 10000)
						.OfType<Order>()
						.ToList();
				}
				Console.ReadLine();
			}
		}
	}

	public class Employees_Search : AbstractIndexCreationTask<Employee, Employees_Search.Result>
	{
		public class Result
		{
			public string Query;
		}

		public Employees_Search()
		{
			Map = employees =>
				from employee in employees
				select new
				{
					Query = new object[]
					{
						employee.FirstName,
						employee.LastName,
						employee.Territories
					}
				};
		}
	}

	public class Orders_Products : AbstractIndexCreationTask<Order, Orders_Products.Result>
	{
		public class Result
		{
			public string Product;
		}

		public Orders_Products()
		{
			Map = orders =>
				from order in orders
				select new
				{
					Product = order.Lines.Select(x => x.Product)
				};
		}
	}

	public class Orders_Totals : AbstractIndexCreationTask<Order>
	{
		public class Result
		{
			public double Total;
		}

		public Orders_Totals()
		{
			Map = orders =>
				from order in orders
				select new
				{
					Total = order.Lines.Sum(l => (l.Quantity * l.PricePerUnit) * (1 - l.Discount))
				};
		}
	}

	public class User
	{
		public string Name;
		public int Age;
	}
}