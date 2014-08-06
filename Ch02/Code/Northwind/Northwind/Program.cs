using System;
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

			long nextIdentity = documentStore.DatabaseCommands.SeedIdentityFor("products");

			using (var session = documentStore.OpenSession())
			{
				var product = new Product {Id = "products/", Name = "What's my id?"};
				session.Store(product);
				Console.WriteLine(product.Id);
				session.SaveChanges();
				Console.WriteLine(product.Id);
			}
		}
	}
}
