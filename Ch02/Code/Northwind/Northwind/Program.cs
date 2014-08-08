using System;
using Orders;
using Raven.Abstractions.Data;
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
				var product = session.Load<Product>("products/1");
				session.SaveChanges();
			}
		}

		public ActionResult Product(int id)
		{
			Product product = DocumentSession.Load<Product>(id);
			Etag etag = DocumentSession.Advanced.GetEtagFor(product);

			return Json(new
			{
				Document = product,
				Etag = etag.ToString()
			})
		}
	}
}
