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

			using (var session = documentStore.OpenSession())
			{
				var p = session.Load<Product>("products/1");
				Console.WriteLine(p.Name);
			}
		}
	}
}
