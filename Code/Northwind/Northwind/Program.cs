using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Runtime.Remoting;
using System.Runtime.Remoting.Messaging;
using System.Text;
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
				Url = "http://localhost:8080",
				DefaultDatabase = "Northwind"
			};

			documentStore.Initialize();

			new JustOrderIdAndcompanyName().Execute(documentStore);

			using (var session = documentStore.OpenSession())
			{
				List<string> list = session.Query<Product>().OrderBy(x=>x.Name).Select(x=>x.Name).Skip(25).Take(25).ToList();
				var sb = new StringBuilder("----\t\t\t----\t\t\t----\t\t\t").AppendLine();
				int i = 0;
				foreach (var name in list)
				{
					sb.Append(name).AppendLine();
				}
				var s = sb.ToString();
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
