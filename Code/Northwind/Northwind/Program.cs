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
				Url = "http://raven:8080",
				DefaultDatabase = "nw"
			};

			documentStore.Initialize();

			new JustOrderIdAndcompanyName().Execute(documentStore);

			using (var session = documentStore.OpenSession())
			{
				var orderId = "orders/827";

				var order = session.Load<JustOrderIdAndcompanyName, JustOrderIdAndcompanyName.Result>(orderId);

				Console.WriteLine("{0}\t{1}\t{2}", order.Id, order.CompanyName, order.OrderedAt);

				

			}
		}
	}


	public class JustOrderIdAndcompanyName : AbstractTransformerCreationTask<Order>
	{
		public class Result
		{
			public string Id { get; set; }
			public string CompanyName { get; set; }
			public DateTime OrderedAt { get; set; }
		}

		public JustOrderIdAndcompanyName()
		{
			TransformResults = orders =>
				from order in orders
				let company = LoadDocument<Company>(order.Company)
				select new { order.Id, CompanyName = company.Name, order.OrderedAt };
		}
	}

	public class User
	{
		public string Name;
	}
}
