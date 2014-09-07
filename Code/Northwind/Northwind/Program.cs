using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Expressions;
using Orders;
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
				Url = "http://ayende-pc:8080",
				DefaultDatabase = "Northwind"
			};

			_documentStore.Initialize();

			//new JustOrderIdAndcompanyName().Execute(documentStore);

			Print(query => query.WhereLessThan(o => o.OrderedAt, DateTime.Today));
			Print(query => query.WhereLessThanOrEqual(o => o.OrderedAt, DateTime.Today));
			Print(query => query.WhereGreaterThan(o => o.Freight, 5));
			Print(query => query.WhereGreaterThanOrEqual(o => o.Freight, 5));
			Print(query => query.WhereBetween(o => o.Freight, 5, 10));
			Print(query => query.WhereBetweenOrEqual(o => o.Freight, 5, 10));
			Print(query => query.WhereStartsWith(o => o.ShipVia, "UP"));
			Print(query => query.WhereIn(o => o.Employee, new[]{"employees/1", "employees/2"}));


		}

		public static void Print(Expression<Action<IDocumentQuery<Order>>> action)
		{
			var expressionToString = ExpressionStringBuilder.ExpressionToString(new DocumentConvention(), false, typeof(object), "orders", action.Body);
			Console.Write(expressionToString);

			Console.Write(";\r\n\t");

			var documentQuery = _documentStore.OpenSession().Advanced.DocumentQuery<Order>();
			action.Compile()(documentQuery);
			Console.WriteLine(documentQuery.ToString());
		}
	}

	public class JustOrderIdAndcompanyName : AbstractTransformerCreationTask<Order>
	{
		public JustOrderIdAndcompanyName()
		{
			TransformResults = orders =>
				from order in orders
				let company = LoadDocument<Company>(order.Company)
				select new { order.Id, CompanyName = company.Name, order.OrderedAt };
		}

		public class Result
		{
			public string Id { get; set; }
			public string CompanyName { get; set; }
			public DateTime OrderedAt { get; set; }
		}
	}

	public class User
	{
		public string Name;
	}
}