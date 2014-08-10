using System;
using System.Runtime.Remoting.Messaging;
using Orders;
using Raven.Abstractions.Data;
using Raven.Client.Document;

namespace Northwind
{
	internal class Program
	{
		private static void Main(string[] args)
		{
			var documentStore = new DocumentStore
			{
				Url = "http://localhost:8080",
				DefaultDatabase = "Northwind"
			};

			documentStore.Initialize();

			using (documentStore.AggressivelyCache())
			{
				for (int i = 0; i < 10; i++)
				{
					using (var session = documentStore.OpenSession())
					{
						var product = session.Load<Product>("products/1");
						Console.WriteLine(product.Name);
					}
					Console.ReadLine();
				}
			}
		}
	}
}
