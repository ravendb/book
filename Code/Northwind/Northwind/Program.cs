using System;
using System.Collections.Generic;
using System.Linq;
using Orders;
using Raven.Client;
using Raven.Client.Document;
using Raven.Client.Indexes;
using Raven.Client.Linq;

namespace Northwind
{
	internal class Program
	{
		private static void Main(string[] args)
		{
			var documentStore = new DocumentStore
			{
				Url = "http://ayende-pc:8080",
				DefaultDatabase = "Northwind"
			};

			documentStore.Initialize();

			//new JustOrderIdAndcompanyName().Execute(documentStore);

			using (IDocumentSession session = documentStore.OpenSession())
			{
				RavenQueryStatistics stats;
				var q = from product in session.Query<Product>()
							.Statistics(out stats)
					where product.Discontinued == false
					select product;

				q.ToList();

				Console.WriteLine(stats.IndexName);

				q = from product in session.Query<Product>()
							.Statistics(out stats)
					where product.Category == "categories/1"
					select product;

				q.ToList();

				Console.WriteLine(stats.IndexName);

				q = from product in session.Query<Product>()
							.Statistics(out stats)
					where product.Supplier == "suppliers/2" 
					&& product.Discontinued == false
					select product;

				q.ToList();

				Console.WriteLine(stats.IndexName);
			}
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