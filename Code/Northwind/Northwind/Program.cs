using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Runtime.Remoting;
using System.Runtime.Remoting.Messaging;
using Orders;
using Raven.Abstractions.Commands;
using Raven.Abstractions.Data;
using Raven.Client;
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
				DefaultDatabase = "Users"
			};

			documentStore.Initialize();
			string query;
			using (var session = documentStore.OpenSession())
			{
				query = session.Query<Product>()
					.Where(x => x.Discontinued)
					.ToString();
			}

			documentStore.Changes()
					.ForDocument("products/2")
					.Subscribe(notification =>
					{
						Console.WriteLine(notification.Type+ " on document "+ notification.Id);
					})
		}
	}

	public class User
	{
		public string Name;
	}
}
