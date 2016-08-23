defmodule Tesla.Adapter.Hackney do
  def call(env) do
    with  {:ok, status, headers, body} <- request(env) do
      format_response(env, status, headers, body)
    end
  end

  defp format_response(env, status, headers, body) do
    headers = Enum.into(headers, %{})

    %{env | status:   status,
            headers:  headers,
            body:     body}
  end

  defp request(env) do
    request(env.method, to_char_list(env.url), Enum.into(env.headers, []), env.body)
  end
  defp request(method, url, headers, %Stream{} = body), do: request_stream(method, url, headers, body)
  defp request(method, url, headers, body) when is_function(body), do: request_stream(method, url, headers, body)
  defp request(method, url, headers, body) do
    handle :hackney.request(method, url, headers, body || '')
  end


  defp request_stream(method, url, headers, body) do
    {:ok, ref} = :hackney.request(method, url, headers, :stream)
    for data <- body, do: :ok = :hackney.send_body(ref, data)
    handle :hackney.start_response(ref)
  end

  defp handle({:ok, status, headers}), do: {:ok, status, headers, []}
  defp handle({:ok, status, headers, ref}) do
    with {:ok, body} <- :hackney.body(ref) do
      {:ok, status, headers, body}
    end
  end
end
