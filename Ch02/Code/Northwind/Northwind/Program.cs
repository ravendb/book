using System;
using System.Linq;
using Orders;
using Raven.Client;
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
				var orders = session.Query<Order>().Include(x=>x.Company)
					.Where(x => x.Company == "companies/1")
					.ToList();
			}
		}
	}
}
