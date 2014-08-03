using System;
using System.Linq;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Controllers;
using System.Web.Mvc;
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
				// work with the session

				session.SaveChanges();
			}
		}
	}

	public abstract class BaseRavenDBController : Controller
	{
		public IDocumentSession DocumentSession { get; set; }

		protected override void OnActionExecuting(ActionExecutingContext filterContext)
		{
			DocumentSession = DocumentStoreHolder.Store.OpenSession();
		}

		protected override void OnActionExecuted(ActionExecutedContext filterContext)
		{
			using (DocumentSession)
			{
				if (DocumentSession == null || filterContext.Exception != null)
					return;
				DocumentSession.SaveChanges();
			}
		}
	}

	public abstract class BaseRavenDBApiController : ApiController
	{
		public IAsyncDocumentSession DocumentSession { get; set; }

		public override async Task<HttpResponseMessage> ExecuteAsync(HttpControllerContext controllerContext, CancellationToken cancellationToken)
		{
			using (var session = DocumentStoreHolder.Store.OpenAsyncSession())
			{
				var message = await base.ExecuteAsync(controllerContext, cancellationToken);
				await session.SaveChangesAsync();
				return message;
			}
		}
	}
}
