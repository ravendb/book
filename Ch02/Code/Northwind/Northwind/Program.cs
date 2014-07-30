using System;
using System.Linq;
using Orders;
using Raven.Client.Document;

namespace Northwind
{
	class Program
	{
		static void Main(string[] args)
		{
			var documentStore = new DocumentStore
			{
				Url = "http://localhost:8080",
				DefaultDatabase = "Northwind"
			};

			documentStore.Initialize();

			using (var session = documentStore.OpenSession())
			{
				var order = session.Include<Order>(x => x.Company)
					.Include(x => x.Employee)
					.Include(x => x.Lines.Select(l => l.Product))
					.Load("orders/1");
					


			}


		}
	}
}
